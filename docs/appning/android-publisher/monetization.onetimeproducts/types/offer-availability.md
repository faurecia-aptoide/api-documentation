# Enum: `OfferAvailability`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts.purchaseOptions.offers

Availability of one offer in one region. Sent per entry of an offer's `regionalPricingAndAvailabilityConfigs[]` on a write, and returned as `availability` on each entry of `regional_pricing_and_availability_configs[]` on a read.

## Values

- `AVAILABILITY_UNSPECIFIED`: unspecified. The default when the field is omitted.
- `AVAILABLE`: the offer is available in this region.
- `NO_LONGER_AVAILABLE`: the offer is no longer available in this region.

## What `NO_LONGER_AVAILABLE` does and does not do

It withdraws the **offer** for that region. It does not withdraw the one-time product: a buyer in that region still sees the product at its base price.

**Your client must hide a `NO_LONGER_AVAILABLE` region itself.** The read responses return such a region with its prices intact, deliberately, so that a seller-facing surface can show what the region would pay. Nothing in the service filters on this field.

## Not the same enum as the purchase-option one

A purchase option's regional configuration uses a different, longer list, which additionally contains `UNAVAILABLE` **(Appning)**. The two are not interchangeable: `UNAVAILABLE` is rejected on an offer regional configuration.

Purchase-option values: `AVAILABILITY_UNSPECIFIED`, `AVAILABLE`, `UNAVAILABLE` **(Appning)**, `NO_LONGER_AVAILABLE`.

## Local references

- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
- [`../offers/offers.md`](../offers/offers.md)
