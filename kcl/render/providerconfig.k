"""Renders the ClusterProviderConfig for the selected environment.

The composition references this by name as azure-<env>.
"""

import manifests
import ..values
import ..schemas.providerconfig

_e = values.selected

manifests.yaml_stream([
    providerconfig.ClusterProviderConfig {
        metadata.name = "azure-${_e.name}"
        spec.credentials.secretRef = {
            namespace = "crossplane-system"
            name = "azure-creds-${_e.name}"
            key = "credentials"
        }
    }
])
