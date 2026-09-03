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
  - Allowed characters: lowercase letters (`a-z`), digits (`0-9`), and hyphen (`-`).
  - Maximum length: 20 characters.
  - Enforced as `^[a-z0-9-]{1,20}$`. A tag that breaks the rule is rejected with `400`: `Each tag may contain only lower-case letters (a-z), numbers (0-9) and hyphens (-), and be at most 20 characters.`
  - **A leading hyphen is accepted.** Google describes the value as RFC-1034 conformant, and RFC-1034 labels may not begin with a hyphen — but Google's normative sentence states only the character set and the length, so this service does not add a first-character rule Google does not state. A client may be stricter; this API is not.

Tag content was not validated before 2026-08-18. Tags stored before that date may contain characters this rule would now reject.

## Where tags apply

`offerTags[]` may be set at three levels — one-time product, purchase option, and offer — with a maximum of 20 at each level, counted **after** duplicates are removed. Sending 25 tags of which 10 are duplicates stores 15 and is accepted.
