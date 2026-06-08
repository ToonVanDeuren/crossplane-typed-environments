"""Environment: the typed contract every environment must satisfy.

One schema for every environment. integration, acceptance, and production
are the same shape, validated by the same rules. Drift between them stops
being something review has to catch and becomes a render-time error.

Shared infrastructure (subscription, resource group, location, tags) lives at
the top level; per-service input hangs off a typed field (`postgres`), mirroring
the per-service split of the rendered data under schemas/services/.
"""

import regex
import .base
import .services.postgres as pg

schema Environment:
    name: "integration" | "acceptance" | "production"
    subscriptionId: str
    resourceGroup: str
    location: str
    tags: base.Tags
    postgres: pg.PostgresInput

    check:
        regex.match(subscriptionId, r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"), "subscriptionId must be a UUID"
        regex.match(resourceGroup, r"^rg-[a-z0-9-]+$"), "resourceGroup must start with rg- and be kebab-case"
        regex.match(location, r"^[a-z][a-z0-9]+$"), "location must be an Azure region like westeurope"
