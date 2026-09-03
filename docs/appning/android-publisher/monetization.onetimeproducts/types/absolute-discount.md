# Schema: `absoluteDiscount`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers

A fixed amount deducted from the purchase option's base price in one region. One of the three mutually exclusive price overrides an offer may carry per region.

## JSON

```json
{
  "absoluteDiscount": {
    "currencyCode": "string",
    "units": "string",
    "nanos": 0
  }
}
```

The value is a [`Money`](./money.md) object.

## Rules

- `currencyCode` (`string`, required): ISO 4217 uppercase three-letter code.
  - Must be **the same currency as the purchase option's base price for that same region**. A discount in another currency is rejected, even when that currency is used by some other region of the same option.
- `units` (`int64` as string, required): must not be negative.
- `nanos` (`integer`, required): `0` to `999999999`.
- The discount **must not exceed the base price for that region**.
- Zero is accepted and means the region charges the base price unchanged.

Rejections carry `400`:

| Condition | Message |
|---|---|
| not an object | `absoluteDiscount must be a money object.` |
| bad currency format | `Invalid currencyCode. Expected ISO 4217 uppercase 3-letter code (e.g., USD, EUR).` |
| currency differs from the region's base price | `absoluteDiscount currency 'X' does not match the purchase option price currency 'Y' for region 'R'.` |
| negative units, or nanos out of range | `absoluteDiscount must carry non-negative units and nanos (nanos 0 to 999999999).` |
| larger than the base price | `absoluteDiscount must not exceed the purchase option price for region 'R'.` |

## A base price can later fall below a stored discount

The ceiling above is checked when the offer is written. A later write that only changes the purchase option's price can leave a stored discount larger than the new base price. The charged price never goes negative: the discount is capped at the base price at read time, so the region charges zero rather than a negative amount. See [`resolved-price.md`](./resolved-price.md).

## Local references

- [`money.md`](./money.md)
- [`relative-discount.md`](./relative-discount.md)
- [`offer-pricing-variant.md`](./offer-pricing-variant.md)
- [`resolved-price.md`](./resolved-price.md)
