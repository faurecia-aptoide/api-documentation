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
  - Google's range is `-999999999` to `999999999`, with sign rules tying the sign of `nanos` to the sign of `units`.
  - **(Appning — stricter than Google.)** This service accepts **no negative amount**: `nanos` must be `0` to `999999999` and `units` must not be negative. Google's sign rules are therefore unreachable here, and a negative value is rejected with `400`.

## Where a negative amount would be rejected

Every `Money` on this API is a price or a discount, and neither may be negative:

- `units` below zero — `Price units must not be negative.`
- `nanos` outside `0`–`999999999` — `Nanos must be in range 0 to 999999999.`
- a price of exactly zero — `Price must be greater than zero.` A **discount** of zero is accepted and means "no reduction".
