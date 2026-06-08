"""Foundational schemas shared across the input and the rendered resources.

Kept in one module with no imports so every other schema can build on these
without alias indirection: `Tags` is used on the Environment input and carried
into the rendered data; `EnvironmentData` is the base every workload's data
schema inherits.
"""

schema Metadata:
    name: str
    labels?: {str:str}
    annotations?: {str:str}

schema Tags:
    owner: str
    costCenter: str
    dataClassification: "internal" | "confidential"
    # Tenancy. Optional here because environment-wide tags don't know it; the
    # value is per service. Exactly one is required on every rendered workload,
    # enforced on EnvironmentData below and set per service in kcl/render/.
    dedicatedTo?: str
    sharedAcross?: str

schema EnvironmentData:
    """Base for workload-specific EnvironmentConfig data payloads.

    Carries the environment's governance tags, common to every workload. A
    workload data schema inherits it and adds its own fields; EnvironmentConfig.data
    accepts any such schema but rejects an untyped or unknown-keyed dict.

    Every rendered workload must declare its tenancy: a resource is either
    dedicated to one consumer or shared across many, never both and never
    neither. The check turns that governance rule into a render-time error.
    """
    tags: Tags

    check:
        tags.dedicatedTo or tags.sharedAcross, "tenancy must be declared: set tags.dedicatedTo or tags.sharedAcross"
        not (tags.dedicatedTo and tags.sharedAcross), "tags.dedicatedTo and tags.sharedAcross are mutually exclusive"
