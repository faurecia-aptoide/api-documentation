# Enum: `OfferPricingVariant`

Appning extension. Google publishes no equivalent enum — on the wire the variant is expressed by which of the three override fields is present.

Returned on each entry of an offer's regional pricing and availability configurations, to state which kind of price override that region carries. **(Appning)**

## Values

- `NO_OVERRIDE`: the region charges the purchase option's base price unchanged.
- `RELATIVE_DISCOUNT`: the region charges the base price reduced by a fraction.
- `ABSOLUTE_DISCOUNT`: the region charges the base price reduced by a fixed amount.

## Relationship to the write shape

On a write you send exactly one of `noOverride`, `relativeDiscount` or `absoluteDiscount` per region. On a read you receive `pricing_variant` naming which one applies, together with the value itself where there is one.

| You send | You receive |
|---|---|
| `noOverride: {}` | `pricing_variant: "NO_OVERRIDE"` |
| `relativeDiscount: 0.2` | `pricing_variant: "RELATIVE_DISCOUNT"`, `relative_discount: "0.20000000"` |
| `absoluteDiscount: { … }` | `pricing_variant: "ABSOLUTE_DISCOUNT"`, `absolute_discount: { … }` |

## Local references

- [`relative-discount.md`](./relative-discount.md)
- [`absolute-discount.md`](./absolute-discount.md)
- [`resolved-price.md`](./resolved-price.md)
