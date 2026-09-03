# REST Resource: `monetization.onetimeproducts.purchaseOptions.offers`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers

An offer reduces the price of one purchase option in specific regions, for a period.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

## Resource `OneTimeProductOffer`

The read shape on the seller product detail and the buyer catalogue:

```json
{
  "offer_id": "string",
  "state": "OfferState",
  "offer_token": "string",
  "offer_tags": ["string"],
  "price": { "object": "MoneyValue" },
  "discount": { "object": "FlatDiscount" },
  "time_window": { "object": "TimeWindow" },
  "discounted_offer": { "object": "DiscountedOffer" },
  "regional_pricing_and_availability_configs": [{ "object": "OfferRegionalConfig" }]
}
```

Fields:

- `offer_id` (`string`, output only): unique within the purchase option.
- `state` (`OfferState`, output only): see [`../types/offer-state.md`](../types/offer-state.md). Changed only through the lifecycle endpoints.
- `offer_token` (`string`, output only): names this offer on this purchase option of this product. See [`../types/offer-token.md`](../types/offer-token.md).
- `offer_tags[]` (`string`, output only): the tags in effect for this offer, after inheritance.
- `price` (`MoneyValue`, output only): the payable amount for this offer.
- `discount` (`FlatDiscount`, output only): a flattened single-currency summary for clients written before per-region offers existed. **It cannot express a per-region offer** and reports one region only — do not use it to compute a price.
- `time_window` (`TimeWindow`, output only): the schedule in epoch milliseconds, for the same older clients.
- `discounted_offer` (`DiscountedOffer`, output only): the schedule and redemption cap. `null` when the offer has no schedule and no redemption limit.
- `regional_pricing_and_availability_configs[]` (`OfferRegionalConfig`, output only): the per-region price picture, sorted by `region_code`. Each entry carries `base_price` and `resolved_price` so a client never computes a discount itself — see [`../types/resolved-price.md`](../types/resolved-price.md).

> **Read field names are snake_case; write field names are camelCase.** You author an offer with `regionalPricingAndAvailabilityConfigs` and read it back as `regional_pricing_and_availability_configs`. The values are the same.

### Which reads carry which fields

The seller offer reads ([`list.md`](./list.md), [`batchGet.md`](./batchGet.md)) return a **deliberately leaner** shape: `offer_id`, `state`, `offer_tags`, `discounted_offer`, and per region only `region_code`, `availability` and `pricing_variant`.

They carry **no prices** and **no `offer_token`**, because the wildcard forms can span products. For prices and tokens, read the product detail.

## Lifecycle

States and the transitions between them are on [`../types/offer-state.md`](../types/offer-state.md). In summary:

| Endpoint | Effect |
|---|---|
| [`activate.md`](./activate.md) | to `ACTIVE` |
| [`deactivate.md`](./deactivate.md) | to `INACTIVE` |
| [`batchUpdateStates.md`](./batchUpdateStates.md) | to `ACTIVE` or `INACTIVE`, up to 100 offers at once |
| [`batchDelete.md`](./batchDelete.md) | removes offers permanently, in any state |

An offer is served to a buyer only when its state is `ACTIVE` **and** the current time is inside its schedule window. Seller-facing reads apply neither condition, so an operator can see and correct a draft or an expired offer.

## Resource methods

Available on the seller management surface:

- `list`: lists the offers of a purchase option.
- `batchGet`: reads named offers.
- `activate`, `deactivate`: change one offer's state.
- `batchUpdateStates`: changes several offers' states.
- `batchDelete`: deletes offers.

Not implemented: `cancel` (pre-order only, and pre-orders are rejected on write) and `batchUpdate` (offers are written through `oneTimeProducts:batchUpdate`).

## Local references

- [`README.md`](./README.md)
- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
- [`../types/offer-state.md`](../types/offer-state.md)
- [`../types/offer-availability.md`](../types/offer-availability.md)
- [`../types/offer-pricing-variant.md`](../types/offer-pricing-variant.md)
- [`../types/resolved-price.md`](../types/resolved-price.md)
- [`../types/offer-token.md`](../types/offer-token.md)
