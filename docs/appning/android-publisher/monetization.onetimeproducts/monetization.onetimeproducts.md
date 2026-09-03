# REST Resource: `monetization.onetimeproducts`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts

One-time products represent digital goods in an app.

> **Surface:** partner API, `/androidpublisher/v3/…`. The same resource is also written and read on the seller management API under `/sellers/{uid}/…`, where the error envelope and pagination differ — see [`offers/README.md`](./offers/README.md).

## Resource `OneTimeProduct`

```json
{
  "packageName": "string",
  "productId": "string",
  "listings": [{ "object": "OneTimeProductListing" }],
  "taxAndComplianceSettings": { "object": "OneTimeProductTaxAndComplianceSettings" },
  "purchaseOptions": [{ "object": "OneTimeProductPurchaseOption" }],
  "restrictedPaymentCountries": { "object": "RestrictedPaymentCountries" },
  "offerTags": [{ "object": "OfferTag" }],
  "regionsVersion": { "object": "RegionsVersion" }
}
```

Fields:

- `packageName` (`string`, required, immutable): parent app package name.
- `productId` (`string`, required, immutable):
  - Unique within the parent app.
  - Must start with a number or lowercase letter.
  - Allowed characters: `[a-z0-9_.]`.
- `listings[]` (`OneTimeProductListing`, required): must not contain duplicate `languageCode` entries.
- `taxAndComplianceSettings` (`OneTimeProductTaxAndComplianceSettings`): tax and compliance details.
- `purchaseOptions[]` (`OneTimeProductPurchaseOption`, required): buy/rent options.
- `restrictedPaymentCountries` (`RestrictedPaymentCountries`, optional): payment method location restrictions.
- `offerTags[]` (`OfferTag`, optional): up to 20 custom tags.
- `regionsVersion` (`RegionsVersion`, output only): region version used to generate this resource.

## `OneTimeProductListing`

```json
{
  "languageCode": "string",
  "title": "string",
  "description": "string"
}
```

- `languageCode` (`string`, required): BCP-47 code (for example `en-US`).
- `title` (`string`, required): max 55 characters.
- `description` (`string`, required): max 200 characters.

## `OneTimeProductTaxAndComplianceSettings`

```json
{
  "regionalTaxConfigs": [{ "object": "RegionalTaxConfig" }],
  "isTokenizedDigitalAsset": false,
  "regionalProductAgeRatingInfos": [{ "object": "RegionalProductAgeRatingInfo" }],
  "productTaxCategoryCode": "string"
}
```

- `regionalTaxConfigs[]` (`RegionalTaxConfig`): tax configuration by region.
- `isTokenizedDigitalAsset` (`boolean`): whether this product is declared as a tokenized digital asset.
- `regionalProductAgeRatingInfos[]` (`RegionalProductAgeRatingInfo`): currently supported for `US`.
- `productTaxCategoryCode` (`string`): tax category assigned to the product.

## `RegionalTaxConfig`

```json
{
  "regionCode": "string",
  "taxTier": "TaxTier",
  "eligibleForStreamingServiceTaxRate": false,
  "streamingTaxType": "StreamingTaxType"
}
```

- `regionCode` (`string`, required): ISO 3166-2 code (for example `US`).
- `taxTier` (`TaxTier`): reduced tax tier classification.
- `eligibleForStreamingServiceTaxRate` (`boolean`): US-only flag.
- `streamingTaxType` (`StreamingTaxType`): US streaming tax category.

## `OneTimeProductPurchaseOption`

```json
{
  "purchaseOptionId": "string",
  "state": "State",
  "regionalPricingAndAvailabilityConfigs": [{ "object": "RegionalPricingAndAvailabilityConfig" }],
  "newRegionsConfig": { "object": "OneTimeProductPurchaseOptionNewRegionsConfig" },
  "offerTags": [{ "object": "OfferTag" }],
  "taxAndComplianceSettings": { "object": "PurchaseOptionTaxAndComplianceSettings" },
  "buyOption": { "object": "OneTimeProductBuyPurchaseOption" },
  "rentOption": { "object": "OneTimeProductRentPurchaseOption" },
  "offers": [{ "object": "OneTimeProductOffer" }]
}
```

- `purchaseOptionId` (`string`, required, immutable):
  - Unique within the one-time product.
  - Must start with a number or lowercase letter.
  - Allowed characters: `[a-z0-9-]`, max 63 characters.
- `state` (`State`, output only): purchase option state.
- `regionalPricingAndAvailabilityConfigs[]` (`RegionalPricingAndAvailabilityConfig`): pricing and availability by region.
- `newRegionsConfig` (`OneTimeProductPurchaseOptionNewRegionsConfig`): default pricing/availability for future new regions.
- `offerTags[]` (`OfferTag`, optional): up to 20 custom tags.
- `taxAndComplianceSettings` (`PurchaseOptionTaxAndComplianceSettings`, optional): tax/compliance settings.
- `offers[]` (`OneTimeProductOffer`, optional): **(Appning)** offers authored inline on this purchase option, up to 100. Google addresses offers through a separate resource; this service nests them here, and this is the only write path for them. See [`offers/offers.md`](./offers/offers.md).
- Union `purchase_option_type` (exactly one must be set):
  - `buyOption`
  - `rentOption`

### There is no `type` field

Google's purchase option has no top-level `type`, and neither does this one. The union above is the discriminator: send `buyOption` for a purchase, `rentOption` for a rental.

Sending `type` is **rejected** with `400`, not ignored:

```
type is no longer accepted. Send Google's union instead: buyOption for a purchase,
rentOption for a rental. Exactly one of the two.
```

The rejection is triggered by the presence of the key, whatever its value. Sending both `buyOption` and `rentOption` is also rejected, because Google treats them as mutually exclusive.

### `state` on a write

`state` is output only. On this surface it is accepted and ignored; on the seller management surface it is rejected with `400`. Use the state endpoints to change it — see [`purchase-options/batchUpdateStates.md`](./purchase-options/batchUpdateStates.md).

### Enum `State`

- `STATE_UNSPECIFIED`: default value, do not use.
- `DRAFT`: not currently and never previously available to users.
- `ACTIVE`: available to users.
- `INACTIVE`: no longer available to users.
- `INACTIVE_PUBLISHED`: unavailable for purchase but still exposed for billing backward compatibility.

For the allowed transitions between these states, see [`types/purchase-option-state.md`](./types/purchase-option-state.md).

## `OneTimeProductBuyPurchaseOption`

```json
{
  "legacyCompatible": false,
  "multiQuantityEnabled": false
}
```

- `legacyCompatible` (`boolean`, optional):
  - Exposes this option in legacy PBL flows that do not support the one-time products model.
  - At most one buy option can be legacy compatible. This one **is** enforced: a second legacy-compatible option on the same product is rejected, and a state change that would produce two returns `409` with the code `AMBIGUOUS_LEGACY_OPTION`.
  - Must be a real boolean. The strings `"true"` and `"false"` are rejected rather than converted.
- `multiQuantityEnabled` (`boolean`, optional): **(accepted, not enforced)** stored and returned unchanged, but nothing acts on it — a purchase records no quantity and the charged amount is not multiplied. Do not present a quantity selector to a buyer on the strength of this flag.
  - Must be a real boolean. The strings `"true"` and `"false"` are rejected rather than converted.

## `OneTimeProductRentPurchaseOption`

```json
{
  "rentalPeriod": "string",
  "expirationPeriod": "string"
}
```

- `rentalPeriod` (`string`, required): entitlement duration after purchase completion (ISO 8601).
- `expirationPeriod` (`string`, optional): duration after consumption starts before entitlement revocation (ISO 8601).
- `rentalPreviewPeriod` (`string`, optional): **(Appning)** preview duration. Google publishes no equivalent field.

#### Accepted rental and expiration combinations

**(Appning — stricter than Google.)** Google's reference enumerates no combinations. This service accepts four:

| `rentalPeriod` | Accepted `expirationPeriod` |
|---|---|
| 48 hours | 24 hours |
| 72 hours | 24 hours, 48 hours |
| 30 days | 24 hours, 48 hours, 1 week |
| 60 days | 1 month |

- `expirationPeriod` remains optional; omitting it is accepted with any valid `rentalPeriod`.
- Durations are compared by length, not by spelling, so `PT48H` and `P2D` are the same value.
- `rentalPreviewPeriod` is not part of these combinations.
- An unsupported `rentalPeriod` and a disallowed pairing are two distinct `400` errors.

## `RegionalPricingAndAvailabilityConfig`

```json
{
  "regionCode": "string",
  "price": { "object": "Money" },
  "availability": "Availability"
}
```

- `regionCode` (`string`, required): ISO 3166-2 code.
- `price` (`Money`): region price in that region currency.
- `availability` (`Availability`): purchase option availability.

### Enum `Availability` (purchase option)

- `AVAILABILITY_UNSPECIFIED`: unspecified, do not use.
- `AVAILABLE`: available to users.
- `NO_LONGER_AVAILABLE`: no longer available (valid only after being `AVAILABLE`).
- `AVAILABLE_IF_RELEASED`: initially unavailable; becomes available through a released pre-order offer.
- `AVAILABLE_FOR_OFFERS_ONLY`: not directly available, but linked offers remain available.

## `OneTimeProductPurchaseOptionNewRegionsConfig`

```json
{
  "usdPrice": { "object": "Money" },
  "eurPrice": { "object": "Money" },
  "availability": "Availability"
}
```

- `usdPrice` (`Money`, required): USD price used for future new regions.
- `eurPrice` (`Money`, required): EUR price used for future new regions.
- `availability` (`Availability`, required): whether this config applies to future new regions.

**(accepted, not enforced.)** The whole block is stored and returned unchanged, but nothing in this service observes a new region launching, so no pricing decision reads it. Treat it as a record of intent, not a control.

The block is all-or-nothing: if you send it, all three fields are required. `AVAILABILITY_UNSPECIFIED` is rejected here — send `AVAILABLE` or `NO_LONGER_AVAILABLE`.

Google allows `NO_LONGER_AVAILABLE` only where availability was previously `AVAILABLE`. **This service does not check that**, so the transition is accepted where Google would refuse it.

### Enum `Availability` (new regions config)

- `AVAILABILITY_UNSPECIFIED`: unspecified, do not use.
- `AVAILABLE`: config is used for future new regions.
- `NO_LONGER_AVAILABLE`: config is no longer used for future new regions (valid only after being `AVAILABLE`).

## `PurchaseOptionTaxAndComplianceSettings`

```json
{
  "withdrawalRightType": "WithdrawalRightType"
}
```

- `withdrawalRightType` (`WithdrawalRightType`, optional):
  - Digital content/service classification for eligible regions.
  - Defaults to `WITHDRAWAL_RIGHT_DIGITAL_CONTENT` when unset.

## `OneTimeProductOffer`

**(Appning.)** An offer reduces the price of one purchase option in specific regions, for a period. Authored inline on `purchaseOptions[].offers[]`.

```json
{
  "offerId": "string",
  "discountedOffer": { "object": "DiscountedOffer" },
  "offerTags": [{ "object": "OfferTag" }],
  "regionalPricingAndAvailabilityConfigs": [{ "object": "OfferRegionalPricingAndAvailabilityConfig" }]
}
```

- `offerId` (`string`, required, immutable):
  - Unique within the purchase option.
  - Must start with a number or lowercase letter. Allowed characters `[a-z0-9-]`, at most 63 characters.
- `discountedOffer` (`DiscountedOffer`, required): the schedule and redemption cap. Exactly one offer kind must be set, and `discountedOffer` is the only kind this service accepts.
  - `preOrderOffer` is recognised and **rejected**: `preOrderOffer is not yet supported by this service. Only discountedOffer may be sent.`
- `offerTags[]` (`OfferTag`, optional): up to 20 tags. Three states, and they differ:
  - field absent — the offer inherits the tags of the level above,
  - `[]` — the offer's own tags are cleared,
  - a list — the offer's tags are set to it.
- `regionalPricingAndAvailabilityConfigs[]` (`OfferRegionalPricingAndAvailabilityConfig`, optional): per-region price overrides. No count limit at this level.
- `state` (`OfferState`, output only): see [`types/offer-state.md`](./types/offer-state.md). Accepted and ignored on this surface; rejected on the seller management surface.

An offer never carries a price. It carries a **modifier** applied to the purchase option's price for a region.

### `DiscountedOffer`

```json
{
  "startTime": "string",
  "endTime": "string",
  "redemptionLimit": 0
}
```

- `startTime` (`string`, optional): RFC 3339 timestamp. Inclusive.
- `endTime` (`string`, optional): RFC 3339 timestamp. **Exclusive**, and must be later than `startTime`.
- `redemptionLimit` (`integer`, optional): `0` for unlimited, otherwise `1` to `50`.
  - The range is checked when you write the offer. The count is enforced per buyer at purchase time: a buyer at the cap is refused with `403`.
  - It is a merchandising control, not a security control.

An offer with no `startTime` and no `endTime` has no schedule bound and is always inside its window. Being inside the window is only one of the two conditions for being sellable — see [`types/offer-state.md`](./types/offer-state.md).

### `OfferRegionalPricingAndAvailabilityConfig`

One entry per region, on an offer.

```json
{
  "regionCode": "string",
  "availability": "OfferAvailability",
  "noOverride": {},
  "relativeDiscount": 0,
  "absoluteDiscount": { "object": "Money" }
}
```

- `regionCode` (`string`, required): ISO 3166-1 alpha-2, or a UN M.49 numeric-3 code. Stored and returned exactly as sent — a numeric code is never converted to a letter code.
  - The region **must already be priced on the parent purchase option**, otherwise: `Region 'X' is not priced on this purchase option, so an offer cannot modify it.`
  - A region may appear only once per offer.
- `availability` (`OfferAvailability`, optional): defaults to `AVAILABILITY_UNSPECIFIED`. See [`types/offer-availability.md`](./types/offer-availability.md).
- Union `pricing_override` (**exactly one must be set**):
  - `noOverride` — the region charges the base price unchanged. Google's marker type: send `{}`. The signal is the presence of the key, never its value.
  - `relativeDiscount` — a fraction, not a percentage. See [`types/relative-discount.md`](./types/relative-discount.md).
  - `absoluteDiscount` — a fixed amount in the region's currency. See [`types/absolute-discount.md`](./types/absolute-discount.md).

Sending none of the three, or more than one, is a `400`:

```
Each regional config must carry exactly one of noOverride, relativeDiscount or absoluteDiscount.
Only one of noOverride, relativeDiscount or absoluteDiscount may be set; got X and Y.
```

On a read, each entry additionally returns `pricing_variant`, `base_price` and `resolved_price`, so a client does not compute the discount itself. See [`types/resolved-price.md`](./types/resolved-price.md).

## Where the base price lives

The **purchase option** owns the base price for a region. An offer only modifies it.

- A purchase option that carries its own regional prices uses them **exclusively**, including for regions they do not cover.
- A purchase option that carries none falls back to the product-level regional prices.
- The two are never merged per region.

## Resource methods

On this surface (`/androidpublisher/v3/…`), one method is available:

- `batchUpdate`: creates or updates one or more one-time products.

<details>
<summary>Other Google methods - where they stand</summary>

Four are available, but on the **seller management surface** (`/sellers/{uid}/…`), which uses a different error envelope and paginates differently:

- `list`: lists a seller's one-time products.
- `get`: reads one one-time product.
- `delete`: deletes one one-time product.
- `batchDelete`: deletes several one-time products.

Two are not implemented on any surface:

- `batchGet`: reads one or more one-time products.
- `patch`: creates or updates one one-time product.

At the offer level, `activate`, `deactivate`, `batchUpdateStates`, `batchDelete`, `batchGet` and `list` are available on the seller management surface — see [`offers/README.md`](./offers/README.md). Two are not implemented:

- `offers.cancel`: moves an offer to `CANCELLED`, which applies only to pre-order offers. Pre-orders are rejected on write here, so the method has nothing to act on.
- `offers.batchUpdate`: unnecessary — offers are written through `oneTimeProducts:batchUpdate`.

</details>

## Local references

- [`batchUpdate.md`](./batchUpdate.md)
- [`types/money.md`](./types/money.md)
- [`types/offer-tag.md`](./types/offer-tag.md)
- [`types/restricted-payment-countries.md`](./types/restricted-payment-countries.md)
- [`types/regional-product-age-rating-info.md`](./types/regional-product-age-rating-info.md)
- [`types/regions-version.md`](./types/regions-version.md)
- [`types/withdrawal-right-type.md`](./types/withdrawal-right-type.md)
- [`types/tax-tier.md`](./types/tax-tier.md)
- [`types/streaming-tax-type.md`](./types/streaming-tax-type.md)
- [`types/offer-state.md`](./types/offer-state.md)
- [`types/purchase-option-state.md`](./types/purchase-option-state.md)
- [`types/offer-availability.md`](./types/offer-availability.md)
- [`types/offer-pricing-variant.md`](./types/offer-pricing-variant.md)
- [`types/relative-discount.md`](./types/relative-discount.md)
- [`types/absolute-discount.md`](./types/absolute-discount.md)
- [`types/resolved-price.md`](./types/resolved-price.md)
- [`types/offer-token.md`](./types/offer-token.md)
