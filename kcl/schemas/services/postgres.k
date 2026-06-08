"""Postgres service: the per-environment input and the rendered EnvironmentConfig data.

PostgresInput is what an environment provides for postgres (the server name and
the connection defaults); it hangs off `Environment.postgres`. PostgresData is
the rendered EnvironmentConfig data, inheriting base.EnvironmentData so it carries
the environment's tags. Everything postgres-specific lives here; the generic
schemas never mention it.
"""

import regex
import ..base

schema PostgresInput:
    serverName: str
    adminUser: str = "platform-admin"
    charset: str = "UTF8"
    collation: str = "en_US.utf8"

    check:
        regex.match(serverName, r"^[a-z][a-z0-9-]{2,62}$"), "serverName must match Azure Flexible Server naming rules"

schema PostgresData(base.EnvironmentData):
    serverId: str
    serverFqdn: str
    adminUser: str
    charset: str
    collation: str
