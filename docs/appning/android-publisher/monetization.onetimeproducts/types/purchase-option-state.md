# Enum: `PurchaseOptionState`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts

Lifecycle state of a purchase option. Output only on writes — the state is changed with `purchaseOptions:batchUpdateStates`.

The value list is also given inline on [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md), as part of the `OneTimeProductPurchaseOption` resource. This page adds the transition rules.

## Values

- `STATE_UNSPECIFIED`: default value. Accepted on the wire for compatibility and then rejected — do not send it.
- `DRAFT`: not currently and never previously available to users. Initial state.
- `ACTIVE`: available to users.
- `INACTIVE`: no longer available to users.
- `INACTIVE_PUBLISHED`: unavailable for purchase but still exposed for billing backward compatibility.

## Allowed transitions

| From | To |
|---|---|
| `DRAFT` | `ACTIVE`, `INACTIVE` |
| `ACTIVE` | `INACTIVE`, `INACTIVE_PUBLISHED` |
| `INACTIVE` | `ACTIVE` |
| `INACTIVE_PUBLISHED` | `ACTIVE` |

- Nothing transitions **into** `DRAFT`. It is an initial state only.
- Requesting the state an option is already in succeeds and writes nothing, so a retry is safe.
- Any other transition is rejected with `409` and the code `INVALID_STATE_TRANSITION`.

## State and selling

A purchase option is offered to a buyer only when its state is `ACTIVE` **and** it carries at least one sellable offer. An `ACTIVE` option whose every offer has ended is not offered.

## State and deletion

`purchaseOptions:batchDelete` accepts an option only in `DRAFT`. Any other state is rejected with `409` and the code `PURCHASE_OPTION_NOT_DELETABLE`.

**(Appning — stricter than Google.)** Google places no state restriction on this method. Do not read this rule as Google parity.

## Local references

- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
- [`../purchase-options/batchUpdateStates.md`](../purchase-options/batchUpdateStates.md)
- [`../purchase-options/batchDelete.md`](../purchase-options/batchDelete.md)
