"""Renders the redis EnvironmentConfig for the selected environment.

Composes the generic EnvironmentConfig with the redis-specific RedisData
payload. The composition's function-extra-resources step selects this by the
labels scope=shared, service=redis, environment=<env>. Placement comes from the
environment; sizing falls back to RedisData's defaults.
"""

import manifests
import ..values
import ..schemas.environmentconfig
import ..schemas.services.redis

_e = values.selected

manifests.yaml_stream([
    environmentconfig.EnvironmentConfig {
        metadata = {
            name = "redis-${_e.name}"
            labels = {
                service = "redis"
                environment = _e.name
            }
        }
        data = redis.RedisData {
            resourceGroupName = _e.resourceGroup
            location = _e.location
            tags = _e.tags | {dedicatedTo = "app"}
        }
    }
])
