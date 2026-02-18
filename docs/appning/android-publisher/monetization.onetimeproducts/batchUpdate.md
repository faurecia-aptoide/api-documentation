# Method: `monetization.onetimeproducts.batchUpdate`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts/batchUpdate

Creates or updates one or more one-time products.

## HTTP request

- Method: `POST`
- URL: `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/oneTimeProducts:batchUpdate`
- URL syntax follows gRPC transcoding.

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
      "latencyTolerance": "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE"
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
  - Default is latency-sensitive.

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
