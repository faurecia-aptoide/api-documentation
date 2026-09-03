# Enum: `ProductUpdateLatencyTolerance`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/ProductUpdateLatencyTolerance

Specifies end-to-end propagation latency tolerance for product updates.

## Values accepted by this API

**(Appning — narrower than Google.)** Only two of Google's three values are accepted:

- `PRODUCT_UPDATE_LATENCY_TOLERANCE_UNSPECIFIED`
  - Accepted. Omitting the field is treated as this value.
- `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT`
  - Accepted.

`PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE` is defined by Google but **rejected by this service** with `400`: `Invalid latencyTolerance. Allowed values: …`.

Note that Google documents `…UNSPECIFIED` as defaulting to `…LATENCY_SENSITIVE`. **That is not the behaviour here** — this service treats an absent or unspecified value as `…UNSPECIFIED` and does not fall through to the latency-sensitive tier.

## Google's stated propagation behaviour

The following are **Google's** figures for its own infrastructure, quoted for reference. They are not measurements of this service, and this service does not publish equivalent numbers:

- `…LATENCY_SENSITIVE`: propagates in minutes on average, up to a few hours in rare cases; up to 7,200 updates per app per hour.
- `…LATENCY_TOLERANT`: propagates within 24 hours; up to 720,000 updates per app per hour for batch methods.

Requests to this API are rate limited independently of these figures; exceeding the limit returns `429`.
