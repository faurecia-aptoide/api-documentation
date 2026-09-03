# Enum: `WithdrawalRightType`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/WithdrawalRightType

For products distributed in the EEA, indicates whether the product is classified as digital content or a service.

## Values

- `WITHDRAWAL_RIGHT_UNSPECIFIED`: Google's "default, unused state". Accepted on the wire for parity with the enum and then **rejected** on a write — omit the field instead, which selects the default below.
- `WITHDRAWAL_RIGHT_DIGITAL_CONTENT`: digital content. Google's documented default when the field is absent.
- `WITHDRAWAL_RIGHT_DIGITAL_SERVICE`: digital service.

The field is nested at `purchaseOptions[].taxAndComplianceSettings.withdrawalRightType`, per purchase option. It is never absent from a read: when a seller sets nothing, the response carries `WITHDRAWAL_RIGHT_DIGITAL_CONTENT`.

## What the classification selects

It decides **which** of two region lists the EEA discount-display rule applies to. The two lists are not the same and neither contains the other, so the classification is required in order to apply the rule at all.

| Classification | Regions |
|---|---|
| `WITHDRAWAL_RIGHT_DIGITAL_CONTENT` | `BE`, `HR`, `CZ`, `DK`, `EE`, `FR`, `GR`, `LV`, `PL`, `SE` |
| `WITHDRAWAL_RIGHT_DIGITAL_SERVICE` | `BE`, `HR`, `CZ`, `DK`, `FR`, `GR`, `HU`, `LV`, `NL`, `PL`, `SE` |

In those regions a buyer on a discounted offer must see only the discounted price, with no mention of the offer. See [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md).

## Local references

- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
