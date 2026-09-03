# Method: `monetization.onetimeproducts.purchaseOptions.batchDelete`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions/batchDelete

Deletes purchase options permanently.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## HTTP request

- Method: `POST`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions:batchDelete`
- Sandbox: `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions:batchDelete`

**Per-product only.** There is deliberately no cross-product form: this is a permanent delete, and a cross-product variant would let one request remove options across a seller's whole catalogue.

## Path parameters

- `uid` (`string`, required): the seller. Must be the seller your token belongs to.
- `productId` (`string`, required): the one-time product.

## Request body

```json
{
  "requests": [
    { "purchaseOptionId": "string" }
  ]
}
```

- `requests[]` (required): 1 to 100 entries.
- `purchaseOptionId` (`string`, required): the purchase option to delete.
- The same id must not appear twice. A duplicate is rejected, naming the index where it was first seen — duplicates are not silently collapsed.
- **`productId` is not accepted in the body at all.** It always comes from the path, so a caller cannot believe it targeted a different product.

## Response

`204`, with an empty body.

## What deletion does

- The purchase option is removed permanently, together with its offers and their regional configurations. There is no undelete.
- An id that does not resolve is **skipped, and the request still succeeds.** Deleting something already gone is not an error.

### Only a `DRAFT` option can be deleted

An option that resolves but is not in `DRAFT` is refused with `409` and the code `PURCHASE_OPTION_NOT_DELETABLE`.

**(Appning — stricter than Google.)** Google places no state restriction on this method; it offers a `force` flag instead. Do not read this rule as Google parity. To withdraw an option that has been active, set it to `INACTIVE` with [`batchUpdateStates.md`](./batchUpdateStates.md) instead.

Note the contrast with offers: deleting an **offer** is allowed in any state — see [`../offers/batchDelete.md`](../offers/batchDelete.md).

## Errors

| HTTP | `code` | When | What to change |
|---|---|---|---|
| 400 | `Body.Fields.Missing` | `requests` is absent or empty | send 1 to 100 entries |
| 400 | `Body.Fields.Invalid` | more than 100 entries, or a duplicate `purchaseOptionId` | name each option once |
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to | use your own seller id |
| 404 | `NotFound` | the product does not exist, or the endpoint is not enabled for your account | check the product id |
| 409 | `Conflict` — `PURCHASE_OPTION_NOT_DELETABLE` | the option resolves but is not in `DRAFT` | deactivate it instead |
| 429 | `RequestTooMany` | too many requests | retry after a pause |

## Local references

- [`README.md`](./README.md)
- [`batchUpdateStates.md`](./batchUpdateStates.md)
- [`../offers/batchDelete.md`](../offers/batchDelete.md)
- [`../types/purchase-option-state.md`](../types/purchase-option-state.md)
