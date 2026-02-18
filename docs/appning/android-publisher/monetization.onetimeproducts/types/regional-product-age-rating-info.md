# Schema: `RegionalProductAgeRatingInfo`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/RegionalProductAgeRatingInfo

Age rating details for a specific region.

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
