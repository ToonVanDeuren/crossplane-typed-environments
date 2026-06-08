# crossplane-typed-environments

Working example for the blog post *From YAML to Typed Manifests with KCL* (toon.consulting, forthcoming).

The Crossplane XRDs and compositions build on the `PostgresDatabase` setup from the previous post ([Inside the Composition Pipeline](https://toon.consulting/2026/05/23/inside-the-composition-pipeline/)). The new part is the per-environment configuration: instead of hand-written YAML, every environment is a value file that satisfies one typed KCL `Environment` schema, rendered to the `EnvironmentConfig` and `ClusterProviderConfig` the compositions consume. Two workloads (postgres and redis) share the same machinery, to show the design extends.

> This repo demonstrates the **offline rendering** layer. The **inline rendering** layer (`function-kcl` inside the composition pipeline) is the subject of the next post in the series.

## Layout

The top level splits by what you author (`kcl/`) versus what the cluster applies (`manifests/`):

```
kcl/             the source you edit
manifests/       what the cluster applies
  static/          hand-written, applied as-is
  generated/       rendered from kcl/ — do not edit
```

```
kcl/
  kcl.mod
  schemas/
    base.k                   shared foundations: Metadata, Tags, EnvironmentData (the workload-data base)
    environment.k            Environment: shared input fields + per-service input (postgres)
    environmentconfig.k      the generic EnvironmentConfig (data is a base.EnvironmentData)
    providerconfig.k         the Azure ClusterProviderConfig
    services/                per-service schemas (input + rendered data) — the extension point
      postgres.k             PostgresInput (env input) + PostgresData(base.EnvironmentData)
      redis.k                RedisData(base.EnvironmentData)
  values.k                   the three environments + `selected` (resolves -D env=<name>)
  render/
    providerconfig.k         -> ClusterProviderConfig azure-<env>
    postgres.k               -> EnvironmentConfig postgres-<env>
    redis.k                  -> EnvironmentConfig redis-<env>
manifests/
  static/
    providers/
      family.yaml            provider-family-azure (ships the ClusterProviderConfig CRD)
      postgres.yaml          provider-azure-dbforpostgresql
      redis.yaml             provider-azure-cache
    resources/
      postgres/{xrd,composition}.yaml   PostgresDatabase XRD + pipeline
      redis/{xrd,composition}.yaml      RedisInstance XRD + pipeline
  generated/
    <env>/providerconfig.yaml
    <env>/postgres.yaml
    <env>/redis.yaml
examples/
  postgresdatabase-production.yaml   a namespaced PostgresDatabase (Crossplane v2: no claim)
  redisinstance-production.yaml      a namespaced RedisInstance
Makefile                     render / render-all / vet / fmt / clean
```

## One schema, every environment

`kcl/schemas/environment.k` defines a single `Environment` schema: typed fields, defaults, and `check` rules. The three entries in `kcl/values.k` (`integration`, `acceptance`, `production`) are the same shape validated by the same rules, so drift between them fails the render instead of surviving review.

The schema's `name` field is a literal union (`"integration" | "acceptance" | "production"`) that mirrors each XRD's `spec.environment` enum. Both ends enforce the same closed set.

Shared infrastructure (subscription, resource group, location, tags) sits at the top level; per-service input hangs off a typed field (`postgres: PostgresInput`), mirroring the per-service split of the rendered data under `services/`. A service that needs no per-environment input (redis derives everything from shared fields and defaults) simply has no field here.

Governance `tags` are a required `Tags` sub-schema (`owner`, `costCenter`, `dataClassification` as an `internal | confidential` enum), so every environment must declare them and an unclassified environment fails the render. `Tags` also carries two optional tenancy fields, `dedicatedTo` and `sharedAcross`, which are set per service rather than per environment (see *Extending* below). The same `Tags` type is reused on the way out: it is carried into every rendered `EnvironmentConfig.data`, so what an environment declares is what the cluster sees.

## What gets rendered

One renderer per resource, each emitting a single document:

- `kcl/render/providerconfig.k` -> `ClusterProviderConfig` named `azure-<env>` — referenced by both compositions' `providerConfigRef` (the postgres and cache providers share the Azure family config).
- `kcl/render/postgres.k` -> `EnvironmentConfig` named `postgres-<env>`, labelled `service=postgres`.
- `kcl/render/redis.k` -> `EnvironmentConfig` named `redis-<env>`, labelled `service=redis`.

Each EnvironmentConfig is selected by its composition's `function-extra-resources` step on the labels `scope=shared`, `service=<service>`, `environment=<env>`.

Everything is instantiated from typed schemas in `kcl/schemas/`, so `apiVersion`, `kind`, and the field shapes are fixed by the schema: a wrong field or kind fails the render. The selector `labels` are typed too (`EnvironmentConfigLabels`, with `service` a literal-union of the known services), so a renamed selector label or an unknown service value fails the render instead of silently breaking the match.

## Extending: the generic EnvironmentConfig

`EnvironmentConfig` is workload-agnostic: its `data` is a `base.EnvironmentData`, the base every workload's data schema inherits. The base carries the environment's `tags` and enforces one cross-cutting rule on every rendered workload: tenancy must be declared exactly once — either `dedicatedTo` or `sharedAcross`, never both and never neither. Each renderer sets it per service (redis is `dedicatedTo: app`, the shared postgres server is `sharedAcross: environments`). Each workload then adds its own fields:

- `PostgresData(base.EnvironmentData)` in `services/postgres.k` — the shared Flexible Server (`serverId`, `serverFqdn`, ...).
- `RedisData(base.EnvironmentData)` in `services/redis.k` — cache placement and sizing (`resourceGroupName`, `location`, and `skuName`/`family`/`capacity` defaults).

Each payload is a typed schema rather than a bare `{str:str}` map, so a renamed key a composition reads fails the render. **Adding redis was exactly this pattern:** one new schema in `services/`, one new renderer, one new `static/resources/<service>/` — the generic `EnvironmentConfig` was never touched.

## Rendering

```bash
make render ENV=production    # write manifests/generated/production/{providerconfig,postgres,redis}.yaml
make render-all              # every environment
make vet                     # parse + check every environment, no output written
make check                   # fail if committed manifests/generated is stale (CI runs this)
make fmt                     # format all KCL source

# Direct invocation:
kcl run -D env=production kcl/render/redis.k
```

## How it fits together

No Kustomize. Apply the directories directly:

1. `manifests/static/providers/` is applied first: the Azure family config provider (CRDs) and the two service providers.
2. `manifests/static/resources/` is applied once per cluster: the XRDs and compositions for each workload.
3. `manifests/generated/<env>/` is applied per environment: the `ClusterProviderConfig` and both `EnvironmentConfig`s (`kubectl apply -f manifests/generated/production/`), or pointed at by a GitOps controller.
4. A `PostgresDatabase` or `RedisInstance` (see `examples/`) is created **directly in a namespace** — Crossplane v2 has no separate claim. Its `spec.environment` selects the matching `EnvironmentConfig` and `ClusterProviderConfig`, and the composition builds on the shared infrastructure for that environment.
