# Method: `monetization.onetimeproducts.purchaseOptions.offers.batchGet`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers/batchGet

Reads named offers. A `POST` that changes nothing.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## HTTP request

- Method: `POST`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchGet`
- Sandbox: `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchGet`

## Path parameters

- `uid` (`string`, required): the seller. Must be the seller your token belongs to.
- `productId` (`string`, required): the one-time product, or `-`.
- `purchaseOptionId` (`string`, required): the purchase option, or `-`.

When a path parameter is `-`, every request entry must name it in the body instead.

## Request body

```json
{
  "requests": [
    {
      "offerId": "string",
      "productId": "string",
      "purchaseOptionId": "string"
    }
  ]
}
```

- `requests[]` (required): 1 to 100 entries.
- `offerId` (`string`, required).
- `productId` (`string`): required only when the path `productId` is `-`.
- `purchaseOptionId` (`string`): required only when the path `purchaseOptionId` is `-`.
- The same offer must not appear twice.

## Response body

```json
{
  "oneTimeProductOffers": [{ "object": "OneTimeProductOffer" }]
}
```

- Offers are returned **in the order you asked for them**.
- An offer that does not resolve is **absent from the response**. It is not an error, and there is no `404` for it — compare what you receive against what you asked for.
- The shape is the leaner seller one, with no prices and no `offer_token` — see [`offers.md`](./offers.md).

## Errors

| HTTP | `code` | When |
|---|---|---|
| 400 | `Body.Fields.Invalid` | no entries, more than 100, a duplicate target, or a missing `productId`/`purchaseOptionId` where the path carried `-` |
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to |
| 404 | `NotFound` | the endpoint is not enabled for your account |
| 429 | `RequestTooMany` | too many requests; retry after a pause |

## Local references

- [`offers.md`](./offers.md)
- [`list.md`](./list.md)
