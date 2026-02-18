# Schema: `RegionsVersion`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/RegionsVersion

Version of available regions used by a given resource.

## JSON

```json
{
  "version": "string"
}
```

## Fields

- `version` (`string`, required):
  - Represents the version of the supported region set.
  - Increments when supported locations change substantially.
  - Allows create/update operations to succeed using an older region version and pricing set even when a newer version exists.
