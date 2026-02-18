# Schema: `RestrictedPaymentCountries`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/RestrictedPaymentCountries

Countries where purchases are limited to payment methods registered in the same country.

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
