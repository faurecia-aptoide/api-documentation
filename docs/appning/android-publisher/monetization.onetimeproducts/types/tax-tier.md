# Enum: `TaxTier`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/TaxTier

Tax tier values combine with `regionCode` to determine applicable tax rates. Available tiers and rate mappings vary by region and may change over time.

> **Not implemented by this API.** This schema lives under a one-time product's **product-level** `taxAndComplianceSettings`, which this service does not implement. The block is accepted in a request body for compatibility and then ignored — nothing is parsed, nothing is stored, and no read returns it. Naming `taxAndComplianceSettings` in `updateMask` is **rejected with `400`**, precisely so a caller is told the values will not be stored rather than receiving `200` and losing them.
>
> This page documents Google's schema so the field is recognisable. It does not describe behaviour you can rely on here.
>
> The **purchase-option-level** `taxAndComplianceSettings.withdrawalRightType` is a different field and **is** implemented — see [`withdrawal-right-type.md`](./withdrawal-right-type.md).


## Values

- `TAX_TIER_UNSPECIFIED`
- `TAX_TIER_BOOKS_1`
- `TAX_TIER_NEWS_1`
- `TAX_TIER_NEWS_2`
- `TAX_TIER_MUSIC_OR_AUDIO_1`
- `TAX_TIER_LIVE_OR_BROADCAST_1`
