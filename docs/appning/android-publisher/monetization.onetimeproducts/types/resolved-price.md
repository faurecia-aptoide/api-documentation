# Schema: resolved price

Appning extension. Google publishes no equivalent schema — it returns an offer's price without showing the base price and the deduction separately.

Each entry of an offer's `regionalPricingAndAvailabilityConfigs[]` returns the base price and the price actually charged, so a client never has to compute a discount itself. **(Appning)**

## JSON

```json
{
  "region_code": "string",
  "availability": "OfferAvailability",
  "pricing_variant": "OfferPricingVariant",
  "relative_discount": "string",
  "absolute_discount": { "object": "Money" },
  "base_price": { "object": "MoneyValue" },
  "resolved_price": { "object": "MoneyValue" }
}
```

> **Field naming differs by direction.** You **write** these regions with camelCase names (`regionalPricingAndAvailabilityConfigs`, `regionCode`, `absoluteDiscount`) on `oneTimeProducts:batchUpdate`, and you **read** them back with the snake_case names above. The values are the same; only the key style differs.

`MoneyValue` carries the amount in several forms for convenience:

```json
{
  "currency": "string",
  "value": "string",
  "label": "string",
  "symbol": "string",
  "micros": 0
}
```

## Fields

- `base_price` (`MoneyValue`, output only): the purchase option's price for this region, before any offer discount.
- `resolved_price` (`MoneyValue`, output only): the amount a buyer in this region is charged for this offer.
- Both are `null` when the region has no base price. That is not an error — a regional configuration may exist for a region that is not priced yet.

## How the charged price is derived

```
discount = round_half_up(base_price × relative_discount)   when pricing_variant is RELATIVE_DISCOUNT
discount = absolute_discount                                when pricing_variant is ABSOLUTE_DISCOUNT
discount = 0                                                when pricing_variant is NO_OVERRIDE

resolved_price = base_price − discount
```

- Rounding is half up.
- The **discount** is capped at the base price, so `resolved_price` is never negative and `base_price − discount = resolved_price` always holds exactly across the three returned figures.
- A region an offer does not mention charges the base price unchanged.

## Reading the amount

Use `value` with `currency`. `value` is a decimal string with trailing zeros removed, so a price of five units is `"5"`, not `"5.00"` — **parse it as a decimal and do not assume two decimal places.**

`micros` is the same amount as an integer count of millionths. Do not mix `micros` with a field of the same name from another service without confirming the scale.

## Three prices appear on one offer — they are not interchangeable

| Field | Meaning |
|---|---|
| `regional_pricing_and_availability_configs[].resolved_price` | what a buyer in that region is charged. The authoritative figure |
| `price` | the payable amount for the offer |
| `discount` | a flattened single-currency summary, provided for clients written before per-region offers existed. It cannot express a per-region offer and reports one region only — do not use it to compute a price |

## Local references

- [`money.md`](./money.md)
- [`relative-discount.md`](./relative-discount.md)
- [`absolute-discount.md`](./absolute-discount.md)
- [`offer-pricing-variant.md`](./offer-pricing-variant.md)
