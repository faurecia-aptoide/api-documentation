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

<!-- Phase 3 rows: batchUpdate.md, monetization.onetimeproducts.md -->
<!-- Phase 4 rows: offers/ resource + reads -->
<!-- Phase 5 rows: offers/ lifecycle writes -->
<!-- Phase 6 rows: purchase-options/ -->
<!-- Phase 7 rows: offer_token, redemptionLimit, EEA -->

---

## Re-verification instructions

For the next audit, do not repeat the whole investigation:

1. `git -C <source repo> log --oneline c4dd77a..origin/staging -- app/Dto/Internal/AndroidPublisher/ app/Enums/ app/Services/Product/ app/Services/Offer/ app/Http/Resources/ routes/api.php`
2. If that range is empty, every `verified` row still holds.
3. Otherwise re-derive only the rows whose cited file appears in the range.
4. Read the parser, enum, route or migration — **never** an ADR, docblock or OpenAPI schema. All three were found stale at this commit, and two research passes reached opposite conclusions on R2 purely from which source they read.
