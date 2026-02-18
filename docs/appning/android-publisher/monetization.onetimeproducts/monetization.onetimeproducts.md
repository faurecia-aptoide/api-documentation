# REST Resource: `monetization.onetimeproducts`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts

One-time products represent digital goods in an app.

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
  "rentOption": { "object": "OneTimeProductRentPurchaseOption" }
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
- Union `purchase_option_type` (exactly one must be set):
  - `buyOption`
  - `rentOption`

### Enum `State`

- `STATE_UNSPECIFIED`: default value, do not use.
- `DRAFT`: not currently and never previously available to users.
- `ACTIVE`: available to users.
- `INACTIVE`: no longer available to users.
- `INACTIVE_PUBLISHED`: unavailable for purchase but still exposed for billing backward compatibility.

## `OneTimeProductBuyPurchaseOption`

```json
{
  "legacyCompatible": false,
  "multiQuantityEnabled": false
}
```

- `legacyCompatible` (`boolean`, optional):
  - Exposes this option in legacy Google Play Billing Library (PBL) flows that do not support the one-time products model.
  - At most one buy option can be legacy compatible.
- `multiQuantityEnabled` (`boolean`, optional): allows purchasing multiple units in a single checkout.

## `OneTimeProductRentPurchaseOption`

```json
{
  "rentalPeriod": "string",
  "expirationPeriod": "string"
}
```

- `rentalPeriod` (`string`, required): entitlement duration after purchase completion (ISO 8601).
- `expirationPeriod` (`string`, optional): duration after consumption starts before entitlement revocation (ISO 8601).

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

## Resource methods

- `batchUpdate`: creates or updates one or more one-time products.

<details>
<summary>Other methods - not implemented at the moment</summary>

- `batchDelete`: deletes one or more one-time products.
- `batchGet`: reads one or more one-time products.
- `delete`: deletes one-time product.
- `get`: reads one-time product.
- `list`: lists all one-time products in an app.
- `patch`: creates or updates one-time product.

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
