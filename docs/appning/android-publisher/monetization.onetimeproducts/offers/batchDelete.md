# Method: `monetization.onetimeproducts.purchaseOptions.offers.batchDelete`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers/batchDelete

Deletes offers permanently.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## HTTP request

- Method: `POST`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchDelete`
- Sandbox: `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchDelete`

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

## Response

`204`, with an empty body.

## Deletion is permanent, and not restricted by state

An offer is removed together with its regional configurations. There is no undelete.

Deletion is allowed **in any state**, including `ACTIVE` — this matches Google, which places no state restriction on the method. If you want a reversible withdrawal, use [`deactivate.md`](./deactivate.md) instead.

### One case is refused

**(Appning.)** Deleting the **last remaining offer of an `ACTIVE` purchase option** returns `409` with the code `LAST_OFFER_OF_ACTIVE_OPTION`.

An active purchase option with no offers would fall back to the product's legacy base price, which silently undoes the withdrawal the deletion was meant to achieve. Deactivate the purchase option first, or leave one offer in place.

## Errors

| HTTP | `code` | When | What to change |
|---|---|---|---|
| 400 | `Body.Fields.Missing` | `requests` is absent or empty | send 1 to 100 entries |
| 400 | `Body.Fields.Invalid` | more than 100 entries, a duplicate target, or a missing `productId`/`purchaseOptionId` where the path carried `-` | name each offer once, and supply the ids the path leaves as `-` |
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to | use your own seller id |
| 404 | `NotFound` | an offer does not resolve, or the endpoint is not enabled for your account | check the identifiers |
| 409 | `Conflict` — `LAST_OFFER_OF_ACTIVE_OPTION` | the request would leave an `ACTIVE` purchase option with no offers | deactivate the purchase option first, or keep one offer |
| 429 | `RequestTooMany` | too many requests | retry after a pause |

## Local references

- [`offers.md`](./offers.md)
- [`deactivate.md`](./deactivate.md)
- [`batchUpdateStates.md`](./batchUpdateStates.md)
- [`../types/offer-state.md`](../types/offer-state.md)
