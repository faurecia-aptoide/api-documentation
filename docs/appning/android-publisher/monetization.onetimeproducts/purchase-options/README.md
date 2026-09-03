# Appning Developer API - purchase option lifecycle

Adapted from:

- [REST Resource: monetization.onetimeproducts](https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts)

Purchase options are **written** through `oneTimeProducts:batchUpdate`, nested in `purchaseOptions[]`. See [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md).

The endpoints here change a purchase option's **state** and **delete** options. There is no separate write endpoint for a purchase option.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## Structure

- [`batchUpdateStates.md`](./batchUpdateStates.md): `purchaseOptions:batchUpdateStates`, in both its per-product and cross-product forms
- [`batchDelete.md`](./batchDelete.md): `purchaseOptions:batchDelete`

## More than one purchase option per product

A one-time product may carry **up to 100 purchase options**, and every one of them is stored and served. Earlier versions of this API accepted only a single option named `default`; that restriction is gone.

Each purchase option owns its own regional prices. An option that carries none falls back to the product-level prices — see [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md).

## Local references

- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
- [`../types/purchase-option-state.md`](../types/purchase-option-state.md)
- [`../offers/README.md`](../offers/README.md)
