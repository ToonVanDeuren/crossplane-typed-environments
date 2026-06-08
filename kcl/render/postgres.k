"""Renders the postgres EnvironmentConfig for the selected environment.

Composes the generic EnvironmentConfig with the postgres-specific PostgresData
payload. The composition's function-extra-resources step selects this by the
labels scope=shared, service=postgres, environment=<env>. serverId and
serverFqdn are interpolated from the typed inputs.
"""

import manifests
import ..values
import ..schemas.environmentconfig
import ..schemas.services.postgres as pg

_e = values.selected

manifests.yaml_stream([
    environmentconfig.EnvironmentConfig {
        metadata = {
            name = "postgres-${_e.name}"
            labels = {
                service = "postgres"
                environment = _e.name
            }
        }
        data = pg.PostgresData {
            serverId = "/subscriptions/${_e.subscriptionId}/resourceGroups/${_e.resourceGroup}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${_e.postgres.serverName}"
            serverFqdn = "${_e.postgres.serverName}.postgres.database.azure.com"
            adminUser = _e.postgres.adminUser
            charset = _e.postgres.charset
            collation = _e.postgres.collation
            tags = _e.tags | {sharedAcross = "environments"}
        }
    }
])
