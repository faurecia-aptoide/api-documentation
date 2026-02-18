# Schema: `Money`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/Money

Represents an amount of money in a specific currency.

## JSON

```json
{
  "currencyCode": "string",
  "units": "string",
  "nanos": 0
}
```

## Fields

- `currencyCode` (`string`): three-letter ISO 4217 currency code.
- `units` (`int64` as string): whole units of the amount.
- `nanos` (`integer`):
  - Fractional amount in nanos (`10^-9`).
  - Allowed range: `-999999999` to `999999999`.
  - Sign rules:
    - if `units > 0`, `nanos >= 0`
    - if `units = 0`, `nanos` can be negative, zero, or positive
    - if `units < 0`, `nanos <= 0`
