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
| | | | | | | |

<!-- Phase 2 rows: types/ pages -->
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
