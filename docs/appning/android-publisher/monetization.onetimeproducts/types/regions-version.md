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

## What this API actually checks

**(Appning.)** `items[].regionsVersion.version` is **required and must not be blank** — omitting it is a `400`. Beyond that:

- **The value is not validated.** Any non-empty string is accepted; there is no check that it names a real region-set version.
- **It is not stored or echoed** by the write path, so the semantics above describe Google's model rather than behaviour you can observe here.
- `regionsVersion` is **immutable**: naming it in `updateMask` is rejected with `400` as immutable or output-only.
