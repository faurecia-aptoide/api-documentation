# Method: `monetization.onetimeproducts.purchaseOptions.offers.list`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers/list

Lists the offers of a purchase option.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## HTTP request

- Method: `GET`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers`
- Sandbox: `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers`

## Path parameters

- `uid` (`string`, required): the seller. Must be the seller your token belongs to.
- `productId` (`string`, required): the one-time product. `-` lists across every product of the seller.
- `purchaseOptionId` (`string`, required): the purchase option. `-` lists across every purchase option.

### The `-` wildcard

| `productId` | `purchaseOptionId` | Result |
|---|---|---|
| an id | an id | that purchase option's offers |
| an id | `-` | every offer of that product |
| `-` | `-` | every offer of the seller |
| `-` | an id | **`400`** — a purchase option cannot be named without its product |

## Query parameters

- `pageSize` (`integer`, optional): default `50`, maximum `1000`.
  - Values outside the range are **coerced**, not rejected: below `1` becomes `1`, above `1000` becomes `1000`.
- `pageToken` (`string`, optional): the `nextPageToken` from a previous response.

## Response body

```json
{
  "oneTimeProductOffers": [{ "object": "OneTimeProductOffer" }],
  "nextPageToken": "string"
}
```

- `oneTimeProductOffers[]` (`OneTimeProductOffer`): the offers in this page, in the leaner seller shape — see [`offers.md`](./offers.md).
- `nextPageToken` (`string`): the token for the next page. **The key is always present** and is `null` on the last page.

**Every state is returned**, including `DRAFT` and `INACTIVE`, and offers outside their schedule window. An operator cannot publish a draft they cannot see.

## Errors

| HTTP | `code` | When |
|---|---|---|
| 400 | `Body.Fields.Invalid` | `purchaseOptionId` was named while `productId` was `-` |
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to |
| 404 | `NotFound` | the endpoint is not enabled for your account, or the product does not exist |
| 429 | `RequestTooMany` | too many requests; retry after a pause |

## Local references

- [`offers.md`](./offers.md)
- [`batchGet.md`](./batchGet.md)
- [`../types/offer-state.md`](../types/offer-state.md)
