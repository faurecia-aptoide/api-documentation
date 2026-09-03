# Appning Developer API - one-time product offers

Adapted from:

- [REST Resource: monetization.onetimeproducts.purchaseOptions.offers](https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers)

An offer reduces the price of one purchase option in specific regions, for a period.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

## Two surfaces, one resource

Offers are **written** through `oneTimeProducts:batchUpdate`, nested inside `purchaseOptions[].offers[]`. See [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md).

The endpoints below **read** offers and **change their state**. There is no separate write endpoint for an offer.

## Structure

- [`offers.md`](./offers.md): the `OneTimeProductOffer` read shape and its lifecycle states
- [`list.md`](./list.md): `offers.list`
- [`batchGet.md`](./batchGet.md): `offers:batchGet`
- [`activate.md`](./activate.md): `offers:activate`
- [`deactivate.md`](./deactivate.md): `offers:deactivate`
- [`batchUpdateStates.md`](./batchUpdateStates.md): `offers:batchUpdateStates`
- [`batchDelete.md`](./batchDelete.md): `offers:batchDelete`
- [`offer-token-flow.md`](./offer-token-flow.md): using `offer_token`, and the rules for resolving a price

## Not implemented

- `offers.cancel`: moves an offer to `CANCELLED`, which applies only to pre-order offers. Pre-orders are rejected on write here, so the method has nothing to act on.
- `offers.batchUpdate`: unnecessary — offers are written through `oneTimeProducts:batchUpdate`.

## Local references

- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
- [`../types/offer-state.md`](../types/offer-state.md)
- [`../types/offer-availability.md`](../types/offer-availability.md)
- [`../types/resolved-price.md`](../types/resolved-price.md)
