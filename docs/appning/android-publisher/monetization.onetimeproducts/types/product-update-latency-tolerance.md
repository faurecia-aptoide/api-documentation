# Enum: `ProductUpdateLatencyTolerance`

Adapted from:

- https://developers.google.com/android-publisher/api-ref/rest/v3/ProductUpdateLatencyTolerance

Specifies end-to-end propagation latency tolerance for product updates.

## Values

- `PRODUCT_UPDATE_LATENCY_TOLERANCE_UNSPECIFIED`
  - Defaults to `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE`.
- `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE`
  - Propagates in minutes on average, up to a few hours in rare cases.
  - Throughput limit: up to 7,200 updates per app per hour.
- `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT`
  - Propagates within 24 hours.
  - High throughput for batch methods: up to 720,000 updates per app per hour.
