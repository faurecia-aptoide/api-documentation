# Schema: `relativeDiscount`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers

A proportional reduction applied to the purchase option's base price in one region. One of the three mutually exclusive price overrides an offer may carry per region.

## JSON

```json
{
  "relativeDiscount": 0.2
}
```

## Rules

- `relativeDiscount` (`number`, required when this override is used):
  - **A fraction, not a percentage.** `0.2` means 20% off. `20` is rejected.
  - Must be strictly greater than `0` and strictly less than `1`. Both bounds are exclusive, so neither a free offer nor a zero discount can be expressed this way.
  - Stored and returned at 8 decimal places. A value with more precision than that is normalised before validation, so a number that would round to exactly `0` or `1` is rejected rather than accepted and then rounded.
  - Returned as a decimal string, for example `"0.20000000"`.

Rejections carry `400`:

| Condition | Message |
|---|---|
| not a number | `relativeDiscount must be a number greater than 0 and less than 1.` |
| outside the bounds | `relativeDiscount must be strictly greater than 0 and strictly less than 1.` |

## How the charged price is derived

See [`resolved-price.md`](./resolved-price.md). The discount is computed from the base price and rounded half up.

## Local references

- [`absolute-discount.md`](./absolute-discount.md)
- [`offer-pricing-variant.md`](./offer-pricing-variant.md)
- [`resolved-price.md`](./resolved-price.md)
