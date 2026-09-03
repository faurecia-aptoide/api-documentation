# Schema: `RestrictedPaymentCountries`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/RestrictedPaymentCountries

Countries where purchases are limited to payment methods registered in the same country.

> **Not implemented by this API.** `restrictedPaymentCountries` is accepted in a request body for compatibility and then ignored — nothing is parsed, nothing is stored, and no read returns it. Naming `restrictedPaymentCountries` in `updateMask` is **rejected with `400`**, so a caller is told the values will not be stored rather than receiving `200` and losing them.
>
> This page documents Google's schema so the field is recognisable. It does not describe behaviour you can rely on here.


## JSON

```json
{
  "regionCodes": ["string"]
}
```

## Fields

- `regionCodes[]` (`string`, required):
  - ISO 3166-2 region codes (for example `US`).
  - If empty, no payment-location restrictions are applied.
