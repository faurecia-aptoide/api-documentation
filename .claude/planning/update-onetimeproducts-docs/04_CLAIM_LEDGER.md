# Claim Ledger: update-onetimeproducts-docs

Every claim published by this ticket, with the source that authorises it. **Internal — never deployed** (ADR-005).

**Source of truth:** `web-product-service-laravel` @ `origin/staging` commit `c4dd77a`. All citations are relative to that commit; a line number is only meaningful at that commit.

**Status vocabulary**
- `verified` — re-derived from the cited source; safe to publish.
- `pending` — written but not yet re-derived. **No page ships with a `pending` row** (TR-18).
- `rejected` — the ticket or an in-repo document asserts it; the code contradicts it. Not published; raised on the ticket instead.

**Provenance** — `Google`, `Appning`, `Appning-stricter`, `accepted-not-enforced` (ADR-002). An empty cell is a defect, not a blank.

---

## Rejected claims

Recorded first, because these are the ticket assertions the code contradicts. Each was raised on PAY-1889.

| # | Claim as stated | Source of the claim | What the code says | Evidence @ `c4dd77a` | Status |
|---|---|---|---|---|---|
| R1 | "`purchaseOptions[].type` (`ONE_TIME`/`RENTAL`) is an Appning field, not Google's… both exist here, so they can disagree" | PAY-1889 item 6 | `type` is **rejected on key presence**, with a message directing the caller to Google's union. It is not accepted, so it cannot disagree with anything | `app/Dto/Internal/AndroidPublisher/BatchUpdateItem.php:1234-1240` (ADR-0135, in force via the squash merge that landed it) | `rejected` |
| R2 | "a `buyOption` on a `RENTAL` option is rejected. The mirror case — a `rentOption` on a `ONE_TIME` option — is silently ignored" | PAY-1889 item 6 | Neither half holds. A `buyOption`+`rentOption` payload is caught by the XOR check at `:1248-1259`; the branch at `:1533-1540` is unreachable from the wire. `rentOption` presence *defines* `RENTAL` (`:1242`, `:1269`), so there is no `ONE_TIME` state in which one can be ignored | `BatchUpdateItem.php:1242-1269`, `:1248-1259`, `:1533-1540`; test comment at `tests/Unit/Dto/Internal/AndroidPublisher/BatchUpdateItemTest.php:1656-1668` | `rejected` |
| R3 | "Fields stored but not enforced: `redemptionLimit`, `new_regions_config`, `multi_quantity_enabled`" | PAY-1889 "What is required" item 4 | `redemptionLimit` **is enforced**, per buyer at purchase time, 403 at the cap. The other two hold | `app/Services/Offer/RedemptionLimitGuard.php:209-214`, called from `app/Services/ApplicationPurchaseService.php:158`; counting rule `app/Support/Offers/RedemptionCountRule.php:96-109` | `rejected` (partially — 1 of 3) |

**R3 consequence:** `redemptionLimit` is published per TR-10 (enforced at purchase time, merchandising control), and must appear in **no** "accepted, not enforced" list. `newRegionsConfig` and `multiQuantityEnabled` are published with the `accepted-not-enforced` marker.

**Also noted, not published** — in-repo prose contradicting its own code at this commit. Not ticket claims, so not `rejected` rows; recorded so a later auditor is not misled by them, and offered to the team as a separate ticket:

| Location | Stale claim |
|---|---|
| `docs/architecture/one-time-products.md:674-691`, `:123-126` | `type` is kept and may disagree with the union; the "known asymmetry" paragraph |
| `docs/architecture/one-time-products.md:420-421` | base price "stays authoritative" in `product_prices_country` — contradicted by `:472-481` of the same file |
| `app/Enums/PurchaseOptionType.php:18-26`, `app/Dto/Internal/AndroidPublisher/BuyOption.php:19-24` | union values "must AGREE with" `type` |
| `BatchUpdateItem.php:1204-1209`, `:1477-1495`, `:1994-1998` | `type` defaults to `ONE_TIME`; the two can disagree; `redemptionLimit` enforcement "is not implemented" |
| `app/Services/AndroidPublisher/BatchUpdateService.php:819-820` | base price "stays on the purchase option, in `product_prices_country`" |
| `routes/api.php:250-254` | `{purchaseOptionId}` can only hold `default` |
| `app/Dto/Internal/Purchase/ApplicationPurchaseInput.php:142` | cites a broker constant `V8::BODY_FIELD_OFFER_TOKEN` that exists in neither broker repository |
| `docs/api/v8-one-time-products.openapi.yaml` | `offer_token` "null until minted in a later phase" (`:663-666`); `Offer` schema missing `state`/`discounted_offer`/regional configs (`:658-699`); `PurchaseOption` schema still flat with `type` (`:562-565`, `:641-642`); write schema missing `offers[]` (`:904-938`) |
| `docs/api/v8-one-time-products-console.openapi.yaml` | `offer_token` nullable (`:1499`) and a `null` example (`:232`) |

---

## Changes to text the audit certified as correct

The ticket requires that nothing previously correct is changed without a code check. Two changes were made, both after checking the code. Both are declared on PAY-1889.

| # | Change | Why | Evidence @ `c4dd77a` |
|---|---|---|---|
| C1 | The `<details>` list of six "not implemented" methods is retitled, scoped to the v3 surface, and split into "available on the seller surface" and "not implemented anywhere" | The list was **unscoped**, not wrong. Four of the six are implemented on the seller surface. A reader took it as "the API does not offer these", which is now false | `routes/api.php:195-197`, `:294-297` (list/get/delete/batchDelete on the seller surface); no route matches `oneTimeProducts:batchGet` or a `patch` on this resource. Decision recorded in ADR-004 |
| C2 | **Found during implementation, not in the ticket.** The request-body example's `latencyTolerance` value, and the bullet "Default is latency-sensitive" | The page's own example was **invalid**: this service accepts only `…UNSPECIFIED` and `…LATENCY_TOLERANT` and rejects `…LATENCY_SENSITIVE` with a 400. An integrator copying the documented example received an error. The default is `UNSPECIFIED`, not latency-sensitive | `app/Dto/Internal/AndroidPublisher/BatchUpdateItem.php:44-47` (allowed list), `:56` (default), `:967-974` (rejection) |

C2 is a divergence the audit did not find, in the document it certified as divergence-free. It is the clearest evidence that the per-claim verification this ticket asks for was worth doing.

---

## Published claims

One row per published cap, enum vocabulary, bound, formula, status code and error string. Filled per phase; a page may not merge while any of its rows is `pending`.

| # | Page | Claim | Provenance | Enforced | Source @ `c4dd77a` | Status |
|---|---|---|---|---|---|---|
| P2-01 | `types/offer-state.md` | `OfferState` has exactly three values: `DRAFT`, `ACTIVE`, `INACTIVE` | Google | n/a | `app/Enums/OfferState.php:61`, `:64`, `:67` | `verified` |
| P2-02 | `types/offer-state.md` | `STATE_UNSPECIFIED` is accepted on the wire then rejected; not a value | Google | request boundary | `app/Enums/OfferState.php:70-73` | `verified` |
| P2-03 | `types/offer-state.md` | `CANCELLED` is not supported (pre-order only; pre-orders rejected on write) | Appning | n/a | `app/Enums/OfferState.php:35-41` | `verified` |
| P2-04 | `types/offer-state.md` | Transitions: DRAFT→ACTIVE; ACTIVE→INACTIVE; INACTIVE→ACTIVE. Nothing enters DRAFT | Google | write time | `app/Enums/OfferState.php:84-86` | `verified` |
| P2-05 | `types/offer-state.md` | Same-state request succeeds and writes nothing | Google | write time | `app/Enums/OfferState.php:98-105` | `verified` |
| P2-06 | `types/offer-state.md` | Illegal transition → 409 `INVALID_STATE_TRANSITION` | Google | write time | `app/Services/Product/OfferLifecycleService.php:93-102` | `verified` |
| P2-07 | `types/offer-state.md` | Sellable = state ACTIVE **and** inside schedule; `startTime` inclusive, `endTime` exclusive | Google | read time | `app/Enums/OfferState.php:108-111`; `app/Services/Product/OneTimeProductCatalogService.php:223-224`; `app/Models/Offer.php:129-153` | `verified` |
| P2-08 | `types/offer-state.md` | Seller-facing reads apply neither gate | Appning | n/a | `app/Services/Product/OneTimeProductCatalogService.php:116-128` | `verified` |
| P2-09 | `types/purchase-option-state.md` | Four values: `DRAFT`, `ACTIVE`, `INACTIVE`, `INACTIVE_PUBLISHED`, plus wire-only `STATE_UNSPECIFIED` | Google | n/a | `app/Enums/PurchaseOptionState.php:26`, `:29`, `:32`, `:39`, `:45` | `verified` |
| P2-10 | `types/purchase-option-state.md` | Transitions: DRAFT→{ACTIVE,INACTIVE}; ACTIVE→{INACTIVE,INACTIVE_PUBLISHED}; INACTIVE→ACTIVE; INACTIVE_PUBLISHED→ACTIVE | Google | write time | `app/Enums/PurchaseOptionState.php:58-61` | `verified` |
| P2-11 | `types/purchase-option-state.md` | Deletable in `DRAFT` only → else 409 `PURCHASE_OPTION_NOT_DELETABLE`; **stricter than Google, which has no state restriction** | Appning-stricter | write time | `app/Enums/PurchaseOptionState.php:84-93`, `:128-131` | `verified` |
| P2-12 | `types/purchase-option-state.md` | Option is offered only when ACTIVE **and** carrying a sellable offer | Google | read time | `app/Services/Product/OneTimeProductCatalogService.php:244-245` | `verified` |
| P2-13 | `types/offer-availability.md` | `OfferAvailability` has three values | Google | n/a | `app/Enums/OfferAvailability.php:22-24` | `verified` |
| P2-14 | `types/offer-availability.md` | `NO_LONGER_AVAILABLE` withdraws the offer, not the product; region served **with prices intact**; nothing filters on it, so the client must hide it | Google field, Appning behaviour | not enforced | `app/Enums/OfferAvailability.php:16-18`; `app/Http/Resources/OneTimeProductResource.php:341-342` | `verified` |
| P2-15 | `types/offer-availability.md` | Purchase-option availability is a different, four-value list including `UNAVAILABLE` | Appning (`UNAVAILABLE`) | write time | `app/Enums/ProductPriceAvailability.php:9-12` | `verified` |
| P2-16 | `types/offer-pricing-variant.md` | Three values: `NO_OVERRIDE`, `RELATIVE_DISCOUNT`, `ABSOLUTE_DISCOUNT` | Appning | n/a | `app/Enums/OfferPricingVariant.php:29-31` | `verified` |
| P2-17 | `types/relative-discount.md` | A fraction, not a percentage; strictly `> 0` and `< 1`, both exclusive | Google | write time | `app/Dto/Internal/AndroidPublisher/BatchUpdateItem.php:2320`, messages `:2300`, `:2323` | `verified` |
| P2-18 | `types/relative-discount.md` | Normalised to 8 decimal places before the bound check; returned as a decimal string | Appning | write time | `BatchUpdateItem.php:2318`, `:2306-2317`; `app/Models/OfferRegionalConfig.php:23-26` | `verified` |
| P2-19 | `types/absolute-discount.md` | Currency must equal the base price currency **for that same region** | Appning-stricter | write time | `BatchUpdateItem.php:2372-2377` | `verified` |
| P2-20 | `types/absolute-discount.md` | Must not exceed the region base price; zero is legal | Google | write time | `BatchUpdateItem.php:2390-2396`; `app/Services/AndroidPublisher/BatchUpdateService.php:942-949` | `verified` |
| P2-21 | `types/absolute-discount.md` | `units >= 0`, `nanos` 0–999999999 | Google | write time | `BatchUpdateItem.php:2384` | `verified` |
| P2-22 | `types/resolved-price.md` | `resolved = base − discount`, discount rounded **half up** | Appning | read time | `app/Services/Offer/OfferPriceResolver.php:55-79`, `:142-144` | `verified` |
| P2-23 | `types/resolved-price.md` | The **discount** is clamped to the base price, so the three figures stay consistent and the price is never negative | Appning | read time | `app/Services/Offer/OfferPriceResolver.php:59-68` | `verified` |
| P2-24 | `types/resolved-price.md` | `base_price`/`resolved_price` are `null` when the region has no base price — not an error | Appning | n/a | `app/Http/Resources/OneTimeProductResource.php:388-393` | `verified` |
| P2-25 | `types/resolved-price.md` | Money envelope is `{currency, value, label, symbol, micros}`; `value` has trailing zeros trimmed | Appning | n/a | `OneTimeProductResource.php:505-517`; `app/Dto/Internal/AndroidPublisher/Money.php:96-105` | `verified` |
| P2-26 | `types/resolved-price.md` | Read fields are snake_case; write fields camelCase | Appning | n/a | `OneTimeProductResource.php:378-395` vs `BatchUpdateItem.php:312-318` | `verified` |
| P2-27 | `types/resolved-price.md` | `discount` is a lossy single-currency projection for unmigrated clients; not for computing a price | Appning | n/a | `OneTimeProductResource.php:554-575` | `verified` |
| P2-28 | `types/offer-token.md` | `otk_` + 32 base64url chars = 36 total | Appning | n/a | `app/Support/Offers/OfferToken.php:71-75`, `:95` | `verified` |
| P2-29 | `types/offer-token.md` | One-way digest of product + purchase option + offer ids; not reversible, no decode endpoint | Appning | n/a | `OfferToken.php:86-96`; `app/Services/Offer/OfferIdentityResolver.php:20-30` | `verified` |
| P2-30 | `types/offer-token.md` | Stable across reads; no expiry inside the token | Appning | n/a | `OfferToken.php:62-66` | `verified` |
| P2-31 | `types/offer-token.md` | Present on the catalogue and seller detail reads; **absent** from the seller offers list and `offers:batchGet` | Appning | n/a | `OneTimeProductResource.php:246`; `app/Http/Controllers/Api/Seller/OneTimeProducts/OfferReadController.php:114-133` | `verified` |

| P3-01 | `batchUpdate.md` | Batch size 100 items | Google | request boundary | `app/Http/Controllers/Api/AndroidPublisher/V3/BatchUpdateController.php:28`, `:65-68` | `verified` |
| P3-02 | `batchUpdate.md` | `PURCHASE_OPTIONS_MAX = 100` per product | **Appning** | write time | `BatchUpdateItem.php:118`, enforced `:615-623` | `verified` |
| P3-03 | `batchUpdate.md` | `OFFERS_PER_OPTION_MAX = 100` per purchase option | **Appning** | write time | `BatchUpdateItem.php:120`, enforced `:1859-1867` | `verified` |
| P3-04 | `batchUpdate.md` | `REGIONAL_CONFIGS_MAX = 400` per purchase option | **Appning** | write time | `BatchUpdateItem.php:122`, enforced `:748-756` | `verified` |
| P3-05 | `batchUpdate.md` | The three caps above are **ours, not Google's** — Google publishes no maximum for these arrays | **Appning** | n/a | `BatchUpdateItem.php:78-88` ("These are OURS, not Google's — do not cite them as Google limits") | `verified` |
| P3-06 | `batchUpdate.md` | Options + offers combined ≤ 100 per product | Google | write time | `app/Services/AndroidPublisher/BatchUpdateService.php:56-61` | `verified` |
| P3-07 | `batchUpdate.md` | The combined limit is **non-regression**: over-limit writes proceed with a `warnings[]` entry when they do not increase the count; only an increase is a 400 | **Appning** | write time | `BatchUpdateService.php:613-638` | `verified` |
| P3-08 | `batchUpdate.md` | Offer tags 20 per level, counted after de-duplication | Google | write time | `BatchUpdateItem.php:124`, `:1191-1198`, `:2108-2115`; de-dup rationale `:71-75` | `verified` |
| P3-09 | `batchUpdate.md` | Tag content: `[a-z0-9-]`, at most 20 characters | Google | write time | `BatchUpdateItem.php:173-175` | `verified` |
| P3-10 | `batchUpdate.md` | Ids: start with a digit or lowercase letter, `[a-z0-9-]`, at most 63 characters | Google | write time | `BatchUpdateItem.php:503-505` | `verified` |
| P3-11 | `batchUpdate.md` | Title 55, description 200 characters | Google | write time | `BatchUpdateItem.php:63`, `:65` | `verified` |
| P3-12 | `batchUpdate.md` | `redemptionLimit` 0 or 1–50 | Google | write time (range) | `BatchUpdateItem.php:195`, `:2025-2034`; Google's sentence quoted at `:181-183` | `verified` |
| P3-13 | `batchUpdate.md` | An offer's own regional array has **no** count cap | **Appning** | not enforced | `BatchUpdateItem.php:2129-2225` contains no count check | `verified` |
| P3-14 | `batchUpdate.md` | `updateMask` allowed roots: `listings`, `purchaseOptions`, `offerTags` | **Appning** (narrower) | write time | `BatchUpdateItem.php:515-519` | `verified` |
| P3-15 | `batchUpdate.md` | `taxAndComplianceSettings`, `restrictedPaymentCountries` are **rejected**, with the "values are not stored" message | **Appning** | write time | `BatchUpdateItem.php:545-548`, `:2722-2727` | `verified` |
| P3-16 | `batchUpdate.md` | `packageName`, `productId`, `regionsVersion` rejected as immutable or output only | Google | write time | `BatchUpdateItem.php:558-562`, `:2713-2717` | `verified` |
| P3-17 | `batchUpdate.md` | Mask paths accept an optional `oneTimeProduct.` prefix and snake_case segments | Google | write time | `BatchUpdateItem.php:2703-2712`, `:2741-2764` | `verified` |
| P3-18 | `batchUpdate.md` | Only `listings` and `purchaseOptions` gate parsing; an unnamed array is not read at all | Google | write time | `BatchUpdateItem.php:953-954`, `:1010`, `:1101` | `verified` |
| P3-19 | `batchUpdate.md` | Unknown fields are rejected; at most 10 named plus a "more not listed" error; triggered by key presence | **Appning** | write time | `BatchUpdateItem.php:139`, `:2584-2609`, `:2559-2564` | `verified` |
| P3-20 | `batchUpdate.md` | The `requests` envelope itself is not unknown-key checked | **Appning** | n/a | `BatchUpdateItem.php:229-233` | `verified` |
| P3-21 | `batchUpdate.md` | Missing fields are reported **instead of** invalid ones — the invalid list is discarded when any field is missing | **Appning** | write time | `app/Dto/Internal/AndroidPublisher/BatchUpdateRequest.php:93-98` | `verified` |
| P3-22 | `batchUpdate.md` | 400 `required` / 400 `badRequest` mapping, Google envelope with `location` | Google | n/a | `app/Http/Errors/ErrorCode.php:38`, `:40`, `:76-80`, `:138-140`; `app/Http/Errors/Envelope/GoogleEnvelope.php:38-45`, `:66-77` | `verified` |
| P3-23 | `batchUpdate.md` | 429 on rate limiting | Google | request boundary | `ErrorCode.php:84`; `app/Http/Errors/FrameworkExceptionTranslator.php:77`; route on `throttle:auth` at `routes/api.php:642` | `verified` |
| P3-24 | `batchUpdate.md` | Duplicate `productId` in one batch is an error | Google | write time | `BatchUpdateRequest.php:152-157` | `verified` |
| P3-25 | `batchUpdate.md` | Version segment is optional; `8.` + exactly 8 digits | **Appning** | request boundary | `app/Http/Middleware/StripApiVersionPrefix.php:39`; `bootstrap/app.php:47` | `verified` |
| P3-26 | `batchUpdate.md` | Sandbox host | **Appning** | n/a | `docs/api/v8-one-time-products.openapi.yaml:22-27` | `verified` |
| P3-27 | `batchUpdate.md`, resource page | Writes **replace, not merge**: absent offers are deleted; region sets are delete-then-insert | **Appning** | write time | `BatchUpdateService.php:853-856`, `:884-896` | `verified` |
| P3-28 | resource page | `latencyTolerance` accepts only `UNSPECIFIED` and `LATENCY_TOLERANT`; `LATENCY_SENSITIVE` is rejected; default is `UNSPECIFIED` | **Appning** (narrower) | write time | `BatchUpdateItem.php:44-47`, `:56`, `:967-974` | `verified` |
| P3-29 | resource page | `purchaseOptions[].offers[]` is an Appning extension; Google uses a separate resource | **Appning** | n/a | `BatchUpdateItem.php:424-426` | `verified` |
| P3-30 | resource page | `type` is **rejected on key presence**, with the message directing to the union | **Appning** | write time | `BatchUpdateItem.php:1234-1240` | `verified` |
| P3-31 | resource page | `buyOption` and `rentOption` are mutually exclusive; sending both is rejected | Google | write time | `BatchUpdateItem.php:1248-1259` | `verified` |
| P3-32 | resource page | `state` is accepted and ignored on v3, rejected on the seller surface | **Appning** | write time | `app/Http/Controllers/Api/Seller/OneTimeProducts/OneTimeProductWriteController.php:137-141`, `:145-190` | `verified` |
| P3-33 | resource page | `multiQuantityEnabled` stored, nothing acts on it; no quantity recorded, amount not multiplied | accepted-not-enforced | not enforced | `app/Dto/Internal/AndroidPublisher/BuyOption.php:35-42`; `app/Http/Resources/OneTimeProductResource.php:119-124` | `verified` |
| P3-34 | resource page | Boolean flags must be real booleans; `"true"` is rejected, not coerced | **Appning** | write time | `BatchUpdateItem.php:1567-1570` | `verified` |
| P3-35 | resource page | `legacyCompatible` **is** enforced — at most one per product; 409 `AMBIGUOUS_LEGACY_OPTION` on a colliding state change | Google | write time | `BatchUpdateService.php:534`; `app/Services/Product/PurchaseOptionLifecycleService.php:140-163` | `verified` |
| P3-36 | resource page | `newRegionsConfig` stored and served only; nothing reads it; all-or-nothing when present; `AVAILABILITY_UNSPECIFIED` rejected | accepted-not-enforced | not enforced | `app/Dto/Internal/AndroidPublisher/NewRegionsConfig.php:38-45`; `OneTimeProductResource.php:147-156`; `BatchUpdateItem.php:1374-1382` | `verified` |
| P3-37 | resource page | Google's "`NO_LONGER_AVAILABLE` only after `AVAILABLE`" rule is **not enforced** | accepted-not-enforced | not enforced | `BatchUpdateItem.php:1384-1400` | `verified` |
| P3-38 | resource page | Four rental/expiration combinations; compared by length not spelling; `rentalPreviewPeriod` excluded | **Appning-stricter** | write time | `app/Support/Rental/RentalPeriodMatrix.php:95-104`, `:188-216`; provenance warning `:14-33`; `BatchUpdateItem.php:1313-1315` | `verified` |
| P3-39 | resource page | `rentalPreviewPeriod` is ours, not Google's | **Appning** | write time | `BatchUpdateItem.php:449-450` | `verified` |
| P3-40 | resource page | Offer union: exactly one of `noOverride` / `relativeDiscount` / `absoluteDiscount`, with both error messages | Google | write time | `BatchUpdateItem.php:2245-2268`, `:2255`, `:2263-2264`; `noOverride` presence-only `:2230-2232` | `verified` |
| P3-41 | resource page | An offer region must already be priced on the parent option | **Appning** | write time | `BatchUpdateItem.php:2193-2200` | `verified` |
| P3-42 | resource page | Region codes: alpha-2 or numeric-3, stored verbatim, never converted; unique per offer | Google | write time | `BatchUpdateItem.php:2771-2782`, `:2175-2178` | `verified` |
| P3-43 | resource page | `offerId` unique per option; `preOrderOffer` recognised and rejected | **Appning** | write time | `BatchUpdateItem.php:1907-1914`, `:1969-1976` | `verified` |
| P3-44 | resource page | `offerTags` is tri-state: absent inherits, `[]` clears, a list sets | **Appning** | write time | `BatchUpdateItem.php:2069-2073`; `app/Dto/Internal/AndroidPublisher/OfferWrite.php:41-47` | `verified` |
| P3-45 | resource page | `endTime` is exclusive and must be later than `startTime` | Google | write time | `BatchUpdateItem.php:2016-2022`; `app/Models/Offer.php:129-153` | `verified` |
| P3-46 | resource page | The purchase option owns the base price; own rows used exclusively, else product-level fallback; never merged per region | **Appning** | read time | `OneTimeProductResource.php:418-464`, `:487` | `verified` |
| P3-47 | resource page | `warnings[]` may accompany a 200 response | **Appning** | n/a | `BatchUpdateController.php:74`, `:85-94` | `verified` |
| P45-01 | `offers/*` | Seller surface paths are `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers…` | **Appning** | n/a | `routes/api.php:211-220`, `:259-277` | `verified` |
| P45-02 | `offers/*` | `{uid}` must match the token's seller; every refusal is the same 403 whether the seller exists or not | **Appning** | request boundary | `app/Http/Middleware/SellerAcl.php:36-38`, `:78` | `verified` |
| P45-03 | `offers/*` | Errors use `{code, path, text, data}`, not the Google envelope | **Appning** | n/a | `app/Http/Errors/Envelope/AptSdkEnvelope.php:34-37`; `docs/architecture/error-envelopes.md` envelope table | `verified` |
| P45-04 | `offers/*` | The whole seller surface is gated; a disabled endpoint 404s (published as "limited availability", per ADR-003) | **Appning** | request boundary | `config/services.php:109-129`; routes registered inside the flag check | `verified` |
| P45-05 | `offers/offers.md` | Seller read shape: `offer_id`, `state`, `offer_tags`, `discounted_offer`, and per region only `region_code`, `availability`, `pricing_variant` — no prices, **no `offer_token`** | **Appning** | n/a | `app/Http/Controllers/Api/Seller/OneTimeProducts/OfferReadController.php:103-133` | `verified` |
| P45-06 | `offers/offers.md` | Buyer/detail read shape carries `offer_token`, `price`, `discount`, `time_window`, `discounted_offer`, regional configs | **Appning** | n/a | `app/Http/Resources/OneTimeProductResource.php:234-270` | `verified` |
| P45-07 | `offers/offers.md` | `discount` and `time_window` are projections for older clients; `discount` is lossy and single-region | **Appning** | n/a | `OneTimeProductResource.php:554-575` | `verified` |
| P45-08 | `offers/offers.md` | `discounted_offer` is `null` when start, end and redemption limit are all absent | **Appning** | n/a | `OneTimeProductResource.php:318-320` | `verified` |
| P45-09 | `offers/list.md` | `pageSize` default 50, max 1000, **coerced** not rejected | Google | request boundary | `app/Services/Product/OfferQueryService.php:47`, `:51`, `:85` | `verified` |
| P45-10 | `offers/list.md` | `nextPageToken` key is always present, `null` on the last page | **Appning** | n/a | `OfferReadController.php:63-69` | `verified` |
| P45-11 | `offers/list.md` | `-` wildcard on both path ids; a named option under a wildcard product is a 400 | Google (`-`), **Appning** (the 400) | request boundary | `OfferQueryService.php:53`, `:152-162` | `verified` |
| P45-12 | `offers/list.md` | Every state is returned, `DRAFT` and `INACTIVE` included, and offers outside their window | **Appning** | n/a | `OfferReadController.php:26-28`; `OfferQueryService.php:37-43` | `verified` |
| P45-13 | `offers/batchGet.md` | 1–100 targets; ids required in the body where the path carries `-`; duplicates rejected | Google | request boundary | `app/Http/Requests/OfferTargetsRequest.php:34`, `:44-52`, `:92-108`, `:113-120` | `verified` |
| P45-14 | `offers/batchGet.md` | Response order matches request order | **Appning** | n/a | `OfferQueryService.php:135-141` | `verified` |
| P45-15 | `offers/batchGet.md` | An unresolvable offer is **absent, not a 404** | **Appning** | n/a | `OfferQueryService.php:106-111` | `verified` |
| P45-16 | `offers/activate.md`, `deactivate.md` | No request body; target state fixed (`ACTIVE` / `INACTIVE`); 204 empty | Google | n/a | `app/Http/Controllers/Api/Seller/OneTimeProducts/OfferStateController.php:61`, `:71`, `:129-148` | `verified` |
| P45-17 | `offers/activate.md`, `deactivate.md` | Same-state request succeeds and writes nothing | Google | write time | `app/Enums/OfferState.php:98-105`; `app/Services/Product/OfferLifecycleService.php:108-110` | `verified` |
| P45-18 | `offers/batchUpdateStates.md` | 1–100 entries; 400 for `STATE_UNSPECIFIED`, for `CANCELLED` (own message), and for an unrecognised value | Google | request boundary | `app/Http/Requests/OfferStatesRequest.php:36`, `:52-58`, `:79-110` | `verified` |
| P45-19 | `offers/batchUpdateStates.md` | **`DRAFT` passes validation and then fails with 409** — it is a real enum case, so it is not a 400 | **Appning** | write time | `OfferStatesRequest.php:99-110` (`tryFrom` accepts DRAFT); `app/Enums/OfferState.php:84-86` (nothing enters DRAFT); 409 at `OfferLifecycleService.php:93-102` | `verified` |
| P45-20 | `offers/batchUpdateStates.md` | The batch is all-or-nothing, in one transaction with a row lock per offer | **Appning** | write time | `OfferLifecycleService.php:72-124`, `:74`, `:248-255` | `verified` |
| P45-21 | `offers/batchDelete.md` | Deletion is permanent, cascades to regional configurations, and is **not** state-restricted — matching Google | Google | write time | `OfferLifecycleService.php:127-149` | `verified` |
| P45-22 | `offers/batchDelete.md` | Deleting the last offer of an `ACTIVE` purchase option → 409 `LAST_OFFER_OF_ACTIVE_OPTION`, because the option would fall back to the legacy base price | **Appning** | write time | `OfferLifecycleService.php:178-243`, condition `:210`, `:218-222` | `verified` |
| P45-23 | `offers/README.md`, `offers.md` | `offers.cancel` and `offers.batchUpdate` are not implemented, with their reasons | **Appning** | n/a | `routes/api.php:256-258`; `OfferStateController.php:36-40`; `docs/architecture/decisions/0138-offer-lifecycle-state.md:199-208` | `verified` |
| P45-24 | `offers/*` | 429 on rate limiting | Google | request boundary | `app/Http/Errors/ErrorCode.php:84`; group on `throttle:auth` at `routes/api.php:88` | `verified` |
<!-- Phase 6 rows: purchase-options/ -->
<!-- Phase 7 rows: offer_token, redemptionLimit, EEA -->

---

## Re-verification instructions

For the next audit, do not repeat the whole investigation:

1. `git -C <source repo> log --oneline c4dd77a..origin/staging -- app/Dto/Internal/AndroidPublisher/ app/Enums/ app/Services/Product/ app/Services/Offer/ app/Http/Resources/ routes/api.php`
2. If that range is empty, every `verified` row still holds.
3. Otherwise re-derive only the rows whose cited file appears in the range.
4. Read the parser, enum, route or migration — **never** an ADR, docblock or OpenAPI schema. All three were found stale at this commit, and two research passes reached opposite conclusions on R2 purely from which source they read.
