"""The environments. Same schema, different values.

Every entry is an Environment, so all three are the same shape validated by
the same rules. Adding an environment is a few lines here, not a new file
whose structure can drift. `selected` resolves -D env=<name> to one of them.
"""

import .schemas.environment as s

_region = "westeurope"

_nonProdSubscriptionId = "11111111-1111-1111-1111-111111111111"
_prodSubscriptionId = "22222222-2222-2222-2222-222222222222"

_internalClassification = "internal"
_confidentialClassification = "confidential"

_baseTags = {
    owner = "platform-team"
    costCenter = "engineering-platform"
}

_integration = s.Environment {
    name = "integration"
    subscriptionId = _nonProdSubscriptionId
    resourceGroup = "rg-platform-${name}"
    location = _region
    tags = _baseTags | {dataClassification = _internalClassification}
    postgres = {serverName = "psql-shared-${name}"}
}

_acceptance = s.Environment {
    name = "acceptance"
    subscriptionId = _nonProdSubscriptionId
    resourceGroup = "rg-platform-${name}"
    location = _region
    tags = _baseTags | {dataClassification = _internalClassification}
    postgres = {serverName = "psql-shared-${name}"}
}

_production = s.Environment {
    name = "production"
    subscriptionId = _prodSubscriptionId
    resourceGroup = "rg-platform-${name}"
    location = _region
    tags = _baseTags | {dataClassification = _confidentialClassification}
    postgres = {
        serverName = "psql-shared-${name}"
        adminUser = "psql-admin"
    }
}

_all: {str:s.Environment} = {
    "integration" = _integration
    "acceptance" = _acceptance
    "production" = _production
}

selected: s.Environment = _all[option("env", required=True)]
