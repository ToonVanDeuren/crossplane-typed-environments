"""The generic EnvironmentConfig resource.

EnvironmentConfig is workload-agnostic: its `data` is an EnvironmentData (from
base.k), the base every workload's data schema inherits. To add a workload,
define a new `schema <Workload>Data(base.EnvironmentData)` in its own file (see
postgres.k); this file never changes.
"""

import .base

schema EnvironmentConfigLabels:
    """The labels the composition selects EnvironmentConfigs by.

    scope and service identify the kind of shared config; environment ties it
    to one environment. Typed so a renamed or missing selector label fails the
    render instead of silently breaking selection at reconcile time.
    """
    scope: "shared" = "shared"
    service: "postgres" | "redis"
    environment: str

schema EnvironmentConfigMetadata:
    name: str
    labels: EnvironmentConfigLabels
    annotations?: {str:str}

schema EnvironmentConfig:
    apiVersion: "apiextensions.crossplane.io/v1beta1" = "apiextensions.crossplane.io/v1beta1"
    kind: "EnvironmentConfig" = "EnvironmentConfig"
    metadata: EnvironmentConfigMetadata
    data: base.EnvironmentData
