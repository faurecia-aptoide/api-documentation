# Method: `monetization.onetimeproducts.batchUpdate`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts/batchUpdate

Creates or updates one or more one-time products.

> **Surface:** partner API, `/androidpublisher/v3/…`.
> Authentication is the JWT Bearer model in the project [`README.md`](../../../../README.md#authentication-jwt-bearer).
> Errors use the Google envelope: `{"error": {"code", "message", "errors[]", "status"}}`.

## HTTP request

- Method: `POST`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/androidpublisher/v3/applications/{packageName}/oneTimeProducts:batchUpdate`
- Sandbox: `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/androidpublisher/v3/applications/{packageName}/oneTimeProducts:batchUpdate`
- URL syntax follows gRPC transcoding.
- The version segment (`8.20240517`) is optional. The same endpoint answers with or without it, and the segment must be `8.` followed by exactly eight digits when present.

## Path parameters

- `packageName` (`string`, required): parent app package name. Must match the `packageName` field in all `OneTimeProduct` resources sent in the request.

## Request body

```json
{
  "requests": [
    {
      "oneTimeProduct": { "object": "OneTimeProduct" },
      "updateMask": "string",
      "regionsVersion": { "object": "RegionsVersion" },
      "allowMissing": false,
      "latencyTolerance": "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT"
    }
  ]
}
```

- `requests[]` (`UpdateOneTimeProductRequest`, required):
  - Up to 100 items.
  - Every item must target a different one-time product.

### `UpdateOneTimeProductRequest`

- `oneTimeProduct` (`OneTimeProduct`, required): one-time product to upsert.
- `updateMask` (`string`, required):
  - Comma-separated list of fully qualified field names.
  - Example: `"user.displayName,photo"`.
- `regionsVersion` (`RegionsVersion`, required): available regions version used for the upsert.
- `allowMissing` (`boolean`, optional):
  - If `true`, creates the one-time product when `packageName + productId` does not exist.
  - If a new product is created, `updateMask` is ignored.
- `latencyTolerance` (`ProductUpdateLatencyTolerance`, optional):
  - End-to-end propagation latency tolerance for the product upsert.
  - **(Appning — narrower than Google.)** Only two values are accepted:
    - `PRODUCT_UPDATE_LATENCY_TOLERANCE_UNSPECIFIED`
    - `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT`
  - Google's enum also defines `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE`. **This service rejects it** with `400` and the message `Invalid latencyTolerance. Allowed values: …`.
  - Omitting the field is treated as `PRODUCT_UPDATE_LATENCY_TOLERANCE_UNSPECIFIED`.

### `updateMask` roots

Only the first segment of each path is examined. A path may optionally be prefixed with `oneTimeProduct.`, and `snake_case` segments are accepted and read as `camelCase` — so `one_time_product.purchase_options` and `purchaseOptions` are the same root.

| Root | Behaviour |
|---|---|
| `listings` | drives a write |
| `purchaseOptions` | drives a write |
| `offerTags` | drives a write |
| `taxAndComplianceSettings` | **rejected** — not yet supported by this service. Values sent under it are not stored |
| `restrictedPaymentCountries` | **rejected** — not yet supported by this service. Values sent under it are not stored |
| `packageName`, `productId`, `regionsVersion` | **rejected** — immutable or output only |

**(Appning.)** Google accepts a wider set of roots. The two "not yet supported" roots are rejected rather than accepted and ignored, so a caller is told the values will not be stored instead of receiving `200` and losing them.

Only `listings` and `purchaseOptions` gate parsing. If the mask does not name `listings`, the `listings[]` array is not read at all — no validation runs on it and nothing is written. The same applies to `purchaseOptions`.

Rejections are `400`, with three distinct messages: an immutable root, a not-yet-supported root, and an unsupported root (which lists the roots that are allowed).

## Limits

| Limit | Value | Applies to | Whose rule | Enforced |
|---|---|---|---|---|
| Batch size | 100 | `requests[]` | Google | request boundary |
| Purchase options | 100 | `purchaseOptions[]` per product | **Appning** | write time |
| Offers | 100 | `offers[]` per purchase option | **Appning** | write time |
| Regional configurations | 400 | `regionalPricingAndAvailabilityConfigs[]` per purchase option | **Appning** | write time |
| Purchase options and offers combined | 100 | per one-time product | Google | write time |
| Offer tags | 20 | per product, per purchase option, and per offer, counted after duplicates are removed | Google | write time |
| Tag length | 20 characters | one `OfferTag` | Google | write time |
| Identifier length | 63 characters | `purchaseOptionId`, `offerId` | Google | write time |
| Listing title | 55 characters | `listings[].title` | Google | write time |
| Listing description | 200 characters | `listings[].description` | Google | write time |
| Offer redemptions | `0`, or `1` to `50` | `offers[].discountedOffer.redemptionLimit` | Google | write time for the range; per buyer at purchase time for the count |

An offer's own `regionalPricingAndAvailabilityConfigs[]` has **no** count limit. The 400 above applies to a purchase option's array only.

### The combined limit does not brick a product already over it

The combined limit of 100 purchase options and offers is checked against the state the request would produce:

- Result at or under 100 — the write proceeds.
- Result over 100, but no higher than before the request — the write **proceeds**, and the response carries a `warnings[]` entry saying it was allowed because it did not increase the count.
- Result over 100 and higher than before — `400`, with the message naming the resulting count.

This keeps a product that is already over the limit editable, so a request that reduces the count is possible.

## Unknown fields are rejected

A field name this service does not recognise is an error, not something ignored. The check applies to every object in the payload — the item, the one-time product, each listing, each purchase option, each offer, each regional configuration, each money object, and the nested blocks inside them.

- The response names at most **10** unknown fields, one error each: `Unknown name "<field>": Cannot find field.` The error's location is the object that carried the field.
- If more remain, one further error says `Too many unknown fields: <n> more not listed.`
- The trigger is the **presence of the key**, not its value. `{"fooo": null}` is still an unknown field.
- The `requests` envelope itself is not checked, so a harmless query-string parameter on the request URL does not cause an error.

## Writes replace, they do not merge

Within a purchase option named by the `updateMask`:

- The **offer set is replaced.** An offer that exists today and is absent from your payload is **deleted**.
- A **region set is replaced**, not merged, both on a purchase option and on an offer.

Send the complete intended state for every purchase option you name. A partial list is a deletion.

## Response body

```json
{
  "oneTimeProducts": [
    {
      "object": "OneTimeProduct"
    }
  ]
}
```

- `oneTimeProducts[]` (`OneTimeProduct`):
  - Updated products in the same order as the input `requests[]`.
- `warnings[]` (`string`, optional): **(Appning)** present only when the batch produced a non-blocking warning, such as a write allowed over the combined limit. A warning does not mean the write failed.

## Errors

Errors on this surface use the Google envelope:

```json
{
  "error": {
    "code": 400,
    "message": "string",
    "errors": [{ "message": "string", "domain": "global", "reason": "string", "location": "string" }],
    "status": "INVALID_ARGUMENT"
  }
}
```

`location` names the field path, for example `items[0].oneTimeProduct.purchaseOptions[default].offers[0].offerId`.

| HTTP | `reason` | When |
|---|---|---|
| 400 | `required` | one or more required fields are absent |
| 400 | `badRequest` | one or more fields carry an invalid value, including an unknown field name |
| 401 | — | the JWT is absent, malformed, expired, or exceeds the 15-minute validity policy |
| 429 | — | too many requests; retry after a pause |

### Missing fields are reported before invalid ones

Validation walks the whole batch and collects every problem, so one response reports all it can rather than stopping at the first.

The two kinds are not mixed. **If any required field is absent, the response reports only the absent fields** and the invalid-value errors are not included. After the missing fields are supplied, a second attempt may therefore surface a different set of errors — invalid values that were always present but not yet reported.

Each item in a batch is validated independently, and a duplicate `productId` within one batch is an error: each request must target a different one-time product.

## Authentication

This endpoint is called through the Appning API gateway and must follow the JWT Bearer authentication model documented in the project `README.md`:

- [`Authentication (JWT Bearer)`](../../../../README.md#authentication-jwt-bearer)

Use:

- Header: `Authorization: Bearer <token>`
- JWT signed with `RS256`
- Required claims: `iss` and `sub` equal to `clientId`
- Token validity policy: `exp - iat <= 900` seconds

## Local references

- [`monetization.onetimeproducts.md`](./monetization.onetimeproducts.md)
- [`types/regions-version.md`](./types/regions-version.md)
- [`types/product-update-latency-tolerance.md`](./types/product-update-latency-tolerance.md)
- [`types/offer-state.md`](./types/offer-state.md)
- [`types/purchase-option-state.md`](./types/purchase-option-state.md)
- [`types/offer-availability.md`](./types/offer-availability.md)
- [`types/relative-discount.md`](./types/relative-discount.md)
- [`types/absolute-discount.md`](./types/absolute-discount.md)
- [`types/resolved-price.md`](./types/resolved-price.md)
