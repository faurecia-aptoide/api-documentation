# Method: `monetization.onetimeproducts.purchaseOptions.offers.batchUpdateStates`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers/batchUpdateStates

Changes the state of several offers in one request.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## HTTP request

- Method: `POST`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchUpdateStates`
- Sandbox: `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchUpdateStates`

## Path parameters

- `uid` (`string`, required): the seller. Must be the seller your token belongs to.
- `productId` (`string`, required): the one-time product.
- `purchaseOptionId` (`string`, required): the purchase option.

## Request body

```json
{
  "requests": [
    {
      "offerId": "string",
      "state": "ACTIVE"
    }
  ]
}
```

- `requests[]` (required): 1 to 100 entries.
- `offerId` (`string`, required): the offer to change.
- `state` (`OfferState`, required): in practice `ACTIVE` or `INACTIVE`.
  - `STATE_UNSPECIFIED` is rejected with `400`: it is accepted for wire parity but is not a settable state.
  - `CANCELLED` is rejected with `400` and its own message: it applies only to pre-order offers, which this service does not support. To withdraw a discounted offer, use `INACTIVE`.
  - An unrecognised value is rejected with `400`.
  - `DRAFT` passes validation, because it is a real state, but **always** fails afterwards with `409` `INVALID_STATE_TRANSITION` — nothing transitions back into `DRAFT`.

## Response

`204`, with an empty body.

**The batch is all or nothing.** If any entry is rejected, no state is changed. Requesting a state an offer is already in is a no-op for that entry and does not fail the batch.

## Errors

| HTTP | `code` | When | What to change |
|---|---|---|---|
| 400 | `Body.Fields.Missing` | `requests` is absent or empty | send 1 to 100 entries |
| 400 | `Body.Fields.Invalid` | more than 100 entries, or a `state` of `STATE_UNSPECIFIED`, `CANCELLED` or an unrecognised value | send `ACTIVE` or `INACTIVE` |
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to | use your own seller id |
| 404 | `NotFound` | an offer does not resolve, or the endpoint is not enabled for your account | check the identifiers |
| 409 | `Conflict` — `INVALID_STATE_TRANSITION` | a requested state is not reachable from an offer's current state, including any request for `DRAFT` | read the current states first; see [`../types/offer-state.md`](../types/offer-state.md) |
| 429 | `RequestTooMany` | too many requests | retry after a pause |

## Local references

- [`offers.md`](./offers.md)
- [`activate.md`](./activate.md)
- [`deactivate.md`](./deactivate.md)
- [`../types/offer-state.md`](../types/offer-state.md)
