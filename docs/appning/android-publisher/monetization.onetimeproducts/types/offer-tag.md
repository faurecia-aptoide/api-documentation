# Schema: `OfferTag`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/OfferTag

Represents a custom product/offer tag.

## JSON

```json
{
  "tag": "string"
}
```

## Fields

- `tag` (`string`):
  - Must conform to RFC-1034.
  - Allowed characters: lowercase letters (`a-z`), digits (`0-9`), and hyphen (`-`).
  - Maximum length: 20 characters.
