"""The Azure ClusterProviderConfig the composition references as azure-<env>."""

import .base

schema ClusterProviderConfig:
    # Served under the azure.m.upbound.io group — the Crossplane v2 (namespaced)
    # provider family, the same group the composed managed resources use.
    apiVersion: "azure.m.upbound.io/v1beta1" = "azure.m.upbound.io/v1beta1"
    kind: "ClusterProviderConfig" = "ClusterProviderConfig"
    metadata: base.Metadata
    spec: ClusterProviderConfigSpec

schema ClusterProviderConfigSpec:
    credentials: Credentials

schema Credentials:
    source: "Secret" = "Secret"
    secretRef: SecretRef

schema SecretRef:
    namespace: str
    name: str
    key: str
