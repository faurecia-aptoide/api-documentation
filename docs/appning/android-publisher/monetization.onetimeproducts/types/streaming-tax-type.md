# Enum: `StreamingTaxType`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/StreamingTaxType

US-specific streaming tax categories.

> **Not implemented by this API.** This schema lives under a one-time product's **product-level** `taxAndComplianceSettings`, which this service does not implement. The block is accepted in a request body for compatibility and then ignored — nothing is parsed, nothing is stored, and no read returns it. Naming `taxAndComplianceSettings` in `updateMask` is **rejected with `400`**, precisely so a caller is told the values will not be stored rather than receiving `200` and losing them.
>
> This page documents Google's schema so the field is recognisable. It does not describe behaviour you can rely on here.
>
> The **purchase-option-level** `taxAndComplianceSettings.withdrawalRightType` is a different field and **is** implemented — see [`withdrawal-right-type.md`](./withdrawal-right-type.md).


## Values

- `STREAMING_TAX_TYPE_UNSPECIFIED`: no telecommunications tax collected.
- `STREAMING_TAX_TYPE_TELCO_VIDEO_RENTAL`: video streaming rental/subscription/pay-per-view category.
- `STREAMING_TAX_TYPE_TELCO_VIDEO_SALES`: video streaming sales category for prerecorded content.
- `STREAMING_TAX_TYPE_TELCO_VIDEO_MULTI_CHANNEL`: multi-channel video streaming category.
- `STREAMING_TAX_TYPE_TELCO_AUDIO_RENTAL`: audio rental/subscription streaming category.
- `STREAMING_TAX_TYPE_TELCO_AUDIO_SALES`: audio sales/permanent download streaming category.
- `STREAMING_TAX_TYPE_TELCO_AUDIO_MULTI_CHANNEL`: multi-channel audio streaming category (for example radio-like streams).
