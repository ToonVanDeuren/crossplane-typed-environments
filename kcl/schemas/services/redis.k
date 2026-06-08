"""Redis workload: the EnvironmentConfig data for provisioning an Azure cache.

RedisData inherits base.EnvironmentData (carrying the environment's tags) and
adds the placement and sizing defaults the composition uses to create an Azure
Cache for Redis. This is the extension point in action: a new workload is a new
file, the generic EnvironmentConfig is untouched.
"""

import ..base

schema RedisData(base.EnvironmentData):
    resourceGroupName: str
    location: str
    skuName: "Basic" | "Standard" | "Premium" = "Standard"
    family: "C" | "P" = "C"
    capacity: int = 1
