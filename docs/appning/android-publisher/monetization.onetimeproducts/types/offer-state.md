# Enum: `OfferState`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers

Lifecycle state of a one-time product offer. Output only on writes — an offer's state is changed with the dedicated lifecycle endpoints, never through `oneTimeProducts:batchUpdate`.

## Values

- `DRAFT`: created but never made available to users. Initial state.
- `ACTIVE`: available to users, provided the offer is also inside its schedule window.
- `INACTIVE`: no longer available to users.

`STATE_UNSPECIFIED` is accepted on the wire for compatibility and then rejected. Do not send it.

`CANCELLED` is not supported. It applies only to pre-order offers, which this service rejects on write.

## Allowed transitions

| From | To |
|---|---|
| `DRAFT` | `ACTIVE` |
| `ACTIVE` | `INACTIVE` |
| `INACTIVE` | `ACTIVE` |

- Nothing transitions **into** `DRAFT`. It is an initial state only.
- Requesting the state an offer is already in succeeds and writes nothing, so a retry is safe.
- Any other transition is rejected with `409` and the code `INVALID_STATE_TRANSITION`.

## Being sellable is two conditions, not one

An offer is served to a buyer only when **both** hold:

1. its state is `ACTIVE`, and
2. the current time is inside its schedule window — `startTime` inclusive, `endTime` exclusive.

An `ACTIVE` offer whose promotion has ended is not sellable. A scheduled `DRAFT` offer is not sellable either.

Seller-facing reads do not apply either condition, so an operator can still see and correct a draft or expired offer.

An offer created through the older flat `discount` / `timeWindow` shape carries that legacy window as well, and it is enforced in addition to the two conditions above — such an offer must satisfy every window it carries. An offer authored through `offers[]` never carries one.

## Local references

- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
- [`purchase-option-state.md`](./purchase-option-state.md)
- [`../offers/offers.md`](../offers/offers.md)
