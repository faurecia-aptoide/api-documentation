# Method: `monetization.onetimeproducts.purchaseOptions.offers.activate`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers/activate

Activates one offer, moving it to `ACTIVE`.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## HTTP request

- Method: `POST`
- URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers/{offerId}:activate`

## Path parameters

- `uid` (`string`, required): the seller. Must be the seller your token belongs to.
- `productId` (`string`, required): the one-time product.
- `purchaseOptionId` (`string`, required): the purchase option.
- `offerId` (`string`, required): the offer.

The `-` wildcard is not accepted here. All four identifiers must be exact.

## Request body

**None.** Every identifier is in the path, and the target state is fixed at `ACTIVE` — you cannot pass a different one.

## Response

`204`, with an empty body.

Requesting a state the offer is already in **succeeds and writes nothing**, so retrying is safe.

## Errors

| HTTP | `code` | When | What to change |
|---|---|---|---|
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to | use your own seller id |
| 404 | `NotFound` | the product, purchase option or offer does not exist, belongs to another seller, or the endpoint is not enabled for your account | check the three identifiers |
| 409 | `Conflict` — `INVALID_STATE_TRANSITION` | `ACTIVE` is not reachable from the offer's current state | read the current `state` first; see [`../types/offer-state.md`](../types/offer-state.md) |
| 429 | `RequestTooMany` | too many requests | retry after a pause |

## Local references

- [`offers.md`](./offers.md)
- [`deactivate.md`](./deactivate.md)
- [`batchUpdateStates.md`](./batchUpdateStates.md)
- [`../types/offer-state.md`](../types/offer-state.md)
