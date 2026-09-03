# Method: `monetization.onetimeproducts.purchaseOptions.batchUpdateStates`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions/batchUpdateStates

Changes the state of several purchase options in one request.

> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.

> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.

## Two forms

| Form | URL | `productId` |
|---|---|---|
| per-product | `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions:batchUpdateStates` | comes from the **path** |
| cross-product **(Appning)** | `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/purchaseOptions:batchUpdateStates` | **required in each entry** |

The cross-product form is an Appning extension. Google scopes this method under a single product.

**The two treat a body-level `productId` differently, and the difference matters:**

- **Per-product:** the path wins. A `productId` in the body is **ignored** — it cannot contradict the URL, and no error is raised if you send one.
- **Cross-product:** there is no path `productId`, so each entry **must** carry one. An entry without it is rejected: `productId is required on the cross-product endpoint.`

## HTTP request

- Method: `POST`
- Per-product URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions:batchUpdateStates`
- Cross-product URL: `https://product.faa.faurecia-aptoide.com/api/8.20240517/sellers/{uid}/inapp/oneTimeProducts/purchaseOptions:batchUpdateStates`
- Sandbox: the same two paths on `https://product-sandbox.faa.faurecia-aptoide.com/api/8.20240517/`

## Path parameters

- `uid` (`string`, required): the seller. Must be the seller your token belongs to.
- `productId` (`string`): present on the per-product form only.

## Request body

```json
{
  "requests": [
    {
      "purchaseOptionId": "string",
      "state": "ACTIVE",
      "productId": "string"
    }
  ]
}
```

- `requests[]` (required): 1 to 100 entries.
- `purchaseOptionId` (`string`, required): the purchase option to change.
- `state` (`PurchaseOptionState`, required): `ACTIVE`, `INACTIVE` or `INACTIVE_PUBLISHED`.
  - `STATE_UNSPECIFIED` is rejected with `400`.
  - `DRAFT` passes validation, because it is a real state, but **always** fails afterwards with `409` — nothing transitions back into `DRAFT`.
- `productId` (`string`): required on the cross-product form, ignored on the per-product form.

Allowed transitions are on [`../types/purchase-option-state.md`](../types/purchase-option-state.md).

## Response

`204`, with an empty body.

**The batch is all or nothing.** If any entry is rejected, no state is changed. Requesting a state an option is already in is a no-op for that entry and does not fail the batch.

## Two side effects worth knowing

1. **Legacy exposure is re-checked.** At most one purchase option per product may be legacy compatible. If a state change would leave two active legacy-compatible options on one product, the request fails with `409` and the code `AMBIGUOUS_LEGACY_OPTION`.
2. **Legacy prices are re-projected.** Options in `DRAFT` or `INACTIVE` are never legacy candidates, so activating or deactivating an option can change which option supplies the product's legacy price.

## Errors

| HTTP | `code` | When | What to change |
|---|---|---|---|
| 400 | `Body.Fields.Missing` | `requests` is absent or empty | send 1 to 100 entries |
| 400 | `Body.Fields.Invalid` | more than 100 entries, a `state` of `STATE_UNSPECIFIED` or an unrecognised value, or a missing `productId` on the cross-product form | correct the entry named in the error |
| 403 | `Authorization.Forbidden` | the `{uid}` is not the seller your token belongs to | use your own seller id |
| 404 | `NotFound` | a purchase option does not resolve, or the endpoint is not enabled for your account | check the identifiers |
| 409 | `Conflict` — `INVALID_STATE_TRANSITION` | a requested state is not reachable from an option's current state, including any request for `DRAFT` | read the current states first |
| 409 | `Conflict` — `AMBIGUOUS_LEGACY_OPTION` | the change would leave two active legacy-compatible options on one product | deactivate the other one, or clear its `legacyCompatible` flag |
| 429 | `RequestTooMany` | too many requests | retry after a pause |

## Local references

- [`README.md`](./README.md)
- [`batchDelete.md`](./batchDelete.md)
- [`../types/purchase-option-state.md`](../types/purchase-option-state.md)
- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
