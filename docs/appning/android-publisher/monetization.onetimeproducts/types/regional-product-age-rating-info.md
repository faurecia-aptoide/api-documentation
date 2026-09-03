# Schema: `RegionalProductAgeRatingInfo`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/RegionalProductAgeRatingInfo

Age rating details for a specific region.

> **Not implemented by this API.** This schema lives under a one-time product's **product-level** `taxAndComplianceSettings`, which this service does not implement. The block is accepted in a request body for compatibility and then ignored — nothing is parsed, nothing is stored, and no read returns it. Naming `taxAndComplianceSettings` in `updateMask` is **rejected with `400`**, precisely so a caller is told the values will not be stored rather than receiving `200` and losing them.
>
> This page documents Google's schema so the field is recognisable. It does not describe behaviour you can rely on here.
>
> The **purchase-option-level** `taxAndComplianceSettings.withdrawalRightType` is a different field and **is** implemented — see [`withdrawal-right-type.md`](./withdrawal-right-type.md).


## JSON

```json
{
  "regionCode": "string",
  "productAgeRatingTier": "ProductAgeRatingTier"
}
```

## Fields

- `regionCode` (`string`): ISO 3166-2 region code.
- `productAgeRatingTier` (`ProductAgeRatingTier`): age-rating tier for the region.

## Enum `ProductAgeRatingTier`

- `PRODUCT_AGE_RATING_TIER_UNKNOWN`: unknown tier.
- `PRODUCT_AGE_RATING_TIER_EVERYONE`: suitable for all ages.
- `PRODUCT_AGE_RATING_TIER_THIRTEEN_AND_ABOVE`: suitable for 13+.
- `PRODUCT_AGE_RATING_TIER_SIXTEEN_AND_ABOVE`: suitable for 16+.
- `PRODUCT_AGE_RATING_TIER_EIGHTEEN_AND_ABOVE`: suitable for 18+.
