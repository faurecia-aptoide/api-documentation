# Code Research: update-onetimeproducts-docs

**Issue:** PAY-1889 · **Phase:** 2 (Research) · **Date:** 2026-09-03

**Source of truth used throughout:** `web-product-service-laravel` at `origin/staging`, commit `c4dd77a` ("PAY-1873: enforce redemptionLimit per buyer at purchase time"). A read-only git worktree was created for the research and every claim below carries a `file:line` reference into it. `main` (`9fe6ed6`) was confirmed 353 commits behind and does not contain this feature set — see `01_DISCOVERY.md`.

> **Method note.** Four independent agents verified the ticket's claims against code. Where an in-repo docblock, architecture note or ADR disagrees with the code, the code is treated as truth and the disagreement is recorded. This mattered: several in-repo prose claims are stale (§6.3).

---

## 1. Codebase Analysis

### 1.1 The repository being changed (`api-documentation`)

13 Markdown pages and one Bash script. No code. Pages follow one strict, repeated shape:

| Page kind | Example | Shape |
|---|---|---|
| Method | `batchUpdate.md` | `# Method: <name>` → `Adapted from:` Google URL → HTTP request (method, URL, gRPC transcoding note) → Path parameters → Request body (JSON block, then a bullet per field) → Response body → Authentication → Local references |
| Resource | `monetization.onetimeproducts.md` | `# REST Resource: <name>` → `Adapted from:` → resource JSON block → `Fields:` bullets → one `## <NestedType>` section per nested type, each with its own JSON block + bullets → `### Enum <Name>` inline → `## Resource methods` (+ a `<details>` block listing unimplemented methods) → Local references |
| Type | `types/money.md` | `# Schema: <Name>` or `# Enum: <Name>` → `Adapted from:` → prose line → `## JSON` → `## Fields` / `## Values` |

Conventions observed, all of which the update must keep:

- Every field bullet is `` `name` `` + `` (`type`, required/optional/immutable/output only) `` + `:` + one-line meaning. Nested constraints are sub-bullets.
- Field types in JSON blocks are placeholders, not examples: `"string"`, `0`, `false`, `{ "object": "TypeName" }`, `[{ "object": "TypeName" }]`.
- Every page opens with `Adapted from:` and a Google URL. The repo describes itself as "a technical extraction of the official documentation (fields, enums, constraints, and behavior) reorganized into local Markdown files" (`docs/.../monetization.onetimeproducts/README.md`).
- Cross-page links are relative (`./batchUpdate.md`, `../../../../README.md#authentication-jwt-bearer`) and every page ends with a `## Local references` list.
- Unimplemented methods are listed inside a collapsed `<details>` block rather than omitted.
- The section index (`docs/.../README.md`) carries a `## Structure` list and a `## Covered sub-links` list; the repo root `README.md` carries the endpoint table. Both must be extended when pages are added.

**No test or lint pattern exists** in this repository — there is no automated check that a documented number matches the code. The only quality gate is human cross-checking, which is precisely what this ticket asks for.

### 1.2 The source-of-truth code (read, not changed)

| Path (at `origin/staging`) | Purpose |
|---|---|
| `app/Dto/Internal/AndroidPublisher/BatchUpdateItem.php` (2783 lines) | All wire-shape validation for `:batchUpdate`. The single most important file for this ticket. |
| `app/Dto/Internal/AndroidPublisher/BatchUpdateRequest.php` | `requests[]` envelope, per-item loop, duplicate-`productId` check, error-bucket merge |
| `app/Services/AndroidPublisher/BatchUpdateService.php` | Rules that need database state: combined option+offer ceiling, `legacyCompatible` uniqueness, price bounds |
| `app/Http/Controllers/Api/AndroidPublisher/V3/BatchUpdateController.php` | v3 partner surface; batch item cap (`MAX_ITEMS = 100`, `:28`) |
| `app/Http/Controllers/Api/Seller/OneTimeProducts/*` | Console surface: `OneTimeProductWriteController`, `OneTimeProductConsoleController`, `OfferReadController`, `OfferStateController`, `PurchaseOptionStateController` |
| `app/Services/Product/OfferLifecycleService.php`, `PurchaseOptionLifecycleService.php` | State-transition enforcement |
| `app/Services/Product/OneTimeProductCatalogService.php` | Sellability gates at catalog-read time |
| `app/Http/Resources/OneTimeProductResource.php` | Buyer/console read shape; mints `offer_token` |
| `app/Enums/OfferState.php`, `PurchaseOptionState.php`, `OfferPricingVariant.php`, `OfferAvailability.php`, `ProductPriceAvailability.php` | Enum vocabularies |
| `app/Support/Offers/OfferToken.php` | `offer_token` minting |
| `app/Support/Offers/RedemptionCountRule.php`, `app/Services/Offer/RedemptionLimitGuard.php` | Per-buyer redemption enforcement |
| `app/Support/Rental/RentalPeriodMatrix.php` | The four allowed rental/expiration pairings |
| `docs/api/v8-one-time-products.openapi.yaml` | Typed contract, buyer + v3 surface. **No drift guard** — needs manual checking |
| `docs/api/v8-one-time-products-console.openapi.yaml` | Typed contract, seller/Console surface. **Drift-guarded** by `tests/Feature/ConsoleOpenApiDriftTest.php` |
| `docs/architecture/one-time-products.md` (798 lines) | Design intent. Partly stale (§6.3) |
| `docs/architecture/error-envelopes.md` | Which error shape applies to which route prefix |

### 1.3 Error-handling convention in the source code

Two buckets, merged once per request (`BatchUpdateItem.php:936-939`, `:27-32`, throw at `:1119-1121`):

- `missing[]` — bare JSON paths of absent required fields.
- `invalid[]` — `FieldError{location, message}` records.

`BatchUpdateRequest::fromArray()` merges across items (`:82-101`) and **`missing` wins**: if any field is missing, the `invalid` list is discarded entirely (`:93-98`). Missing-field responses repeat the path as the message (`:94-97`). Validation never stops at the first error — the whole item is walked so one 400 reports every problem.

| Exception | ErrorCode | HTTP | Google `status` / `reason` |
|---|---|---|---|
| `MissingFieldsException` | `Body.Fields.Missing` | 400 | `INVALID_ARGUMENT` / `required` |
| `InvalidFieldsException` | `Body.Fields.Invalid` | 400 | `INVALID_ARGUMENT` / `badRequest` |
| `ConflictException` | `Conflict` | 409 | — |
| `NotFoundException` | `NotFound` | 404 | — |
| `PurchaseApiException::notAllowed()` | `NotAllowed` | 403 | — |

---

## 2. Architecture Context

### 2.1 How these documents reach a reader — the publishing pipeline

This was previously unknown and it constrains the work:

- The developer portal repo `appning-documentation` serves this repository's Markdown **at request time**: `ApiDocumentationController::show()` reads `resource_path('/views/api-documentation/'.$path)` and renders it through CommonMark (`app/Http/Controllers/ApiDocumentationController.php:26-45`).
- That directory is **git-ignored** in the portal repo (`.gitignore:29`) and holds zero tracked files. It is populated at deploy from this repository. **There is no second copy to edit** — the open question from Discovery is now closed.
- `DirectoryTreeService::buildTree()` walks directories and `.md` files recursively to build the navigation tree (`app/Services/DirectoryTreeService.php:9-70`). It ignores every non-`.md` file (`:41-43`).
- **Filenames become navigation labels** verbatim, except `integration_guide.md` and `index.md` (`DirectoryTreeService.php:66-70`). So a new page's filename is a user-visible label.
- The default page is `README.md`; a path that does not resolve falls back to `index.md` in the same folder (`ApiDocumentationController.php:26`, `:33-38`).
- The URL tree mirrors the file tree (`/api-documentation/<relative path>`), so relative links between pages keep working.

**Consequence:** adding pages and directories is safe and needs no portal change, but filenames must read well as navigation labels, and links must stay relative.

### 2.2 Two API surfaces, not one

This is the central architectural fact for the ticket. The version segment `/api/8.YYYYMMDD/` is stripped before routing by `StripApiVersionPrefix` (`bootstrap/app.php:47`, pattern at `app/Http/Middleware/StripApiVersionPrefix.php:39`), so every path is valid with or without it.

| | Partner / v3 surface | Seller / Console surface |
|---|---|---|
| Path shape | `/androidpublisher/v3/applications/{packageName}/...` | `/sellers/{uid}/inapp/oneTimeProducts/...` |
| Auth | `v3.auth` (Bearer JWT, RS256, `iss`/`sub` = `clientId`) | `jwt` + `seller.acl` + `throttle:auth` (`routes/api.php:88`, `:109`) |
| Authorisation | package-scoped | `seller.acl` maps the JWT subject to a seller and 403s unless it matches `{uid}` — every refusal is the **same** 403 so seller uids cannot be probed (`app/Http/Middleware/SellerAcl.php:36-38`, `:78`) |
| Error envelope | `google` — `{"error":{code,message,errors[],status}}` (`GoogleEnvelope.php:38-45`) | `default` `AptSdkEnvelope` — `{code,path,text,data}` (`AptSdkEnvelope.php:34-37`) |
| Pagination | — | numbered pages with exact total (ADR-0121), **not** cursor |
| One-time-product methods | `:batchUpdate` only | `list`, `get`, `:batchUpdate`, `:batchDelete`, `DELETE`, plus all purchase-option and offer lifecycle endpoints |
| Feature-flagged | No | **Yes** — see §5.1 |

The `google` envelope is scoped to the `/androidpublisher/v3/...` prefix and the architecture note says plainly "**Don't widen**" (`docs/architecture/error-envelopes.md`, envelope table). Envelopes apply to **errors only**; success bodies are returned raw by controllers (`EnvelopeRegistry.php:52`, `bootstrap/app.php:109`).

`:batchUpdate` exists on **both** surfaces and shares persistence through `BatchUpdateService::executeForSeller()`; only seller resolution differs (`OneTimeProductWriteController.php:33-35`). The v3 path is not under `/inapp/`; the Console path is.

### 2.3 The data model that the documents must describe

`Product → PurchaseOption → Offer`, with regional pricing hanging off both of the lower two levels.

Migrations, in ship order (`database/migrations/forward/product/`):

| Date | Migration | What it added |
|---|---|---|
| 2026-06-30 | `create_purchase_options_table` | the purchase-option level |
| 2026-08-03 | `add_state_to_purchase_options` | option lifecycle state |
| 2026-08-15 | `create_offer_regional_configs_table`, `add_variant_and_schedule_to_offers` | per-region offer config; offer schedule |
| 2026-08-17 | `add_rental_expiration_period_to_purchase_options`, `add_new_regions_config_to_purchase_options`, `add_buy_option_flags_to_purchase_options` | rental expiry; `newRegionsConfig`; `legacyCompatible` + `multiQuantityEnabled` |
| 2026-08-19 | `add_state_to_offers` | offer lifecycle state |
| 2026-08-20 | `create_purchase_option_regional_prices_table` | **base price moved onto the option** |
| 2026-09-01 | `add_offer_identity_to_purchases`, `add_redemption_count_index_to_purchases` | offer/option identity on a purchase; redemption counting |

**Price ownership moved** (PAY-1848 phases 2–3, ADR-0150/0151/0152). The option's own `purchase_option_regional_prices` rows are used exclusively when non-empty; otherwise the product's legacy `product_prices_country` map is used (`OneTimeProductResource.php:447-463`, `:487`). Missing base price serialises `base_price`/`resolved_price` as `null` rather than erroring (`:388-393`).

**Multiple purchase options per product are live at this commit.** `BatchUpdateItem.php:588-600`: "The 'exactly one' refusal that lived here through phase 4a **is gone** — phase 4b persists and serves them all, which is safe now and only now, because the price moved onto the option in phases 2-3." The comment at `routes/api.php:250-254` claiming `{purchaseOptionId}` can only hold `default` is **stale**.

### 2.4 States and transitions

`OfferState` — three cases only (`app/Enums/OfferState.php:61-67`). `STATE_UNSPECIFIED` is a wire constant accepted then rejected, not a case (`:73`). `CANCELLED` is deliberately not modelled (`:35-41`).

```
DRAFT    → ACTIVE
ACTIVE   → INACTIVE
INACTIVE → ACTIVE
```
(`OfferState.php:81-88`.) Nothing transitions **into** `DRAFT`. Same-state is legal and writes nothing, so retries are idempotent (`:98-105`). Enforced in `OfferLifecycleService::applyStates()` (`:72-124`); an illegal transition is `ConflictException('INVALID_STATE_TRANSITION: …')` → 409 (`:93-102`). One `DB::transaction` with `lockForUpdate()` per row (`:74`, `:248-255`).

`PurchaseOptionState` — four cases (`app/Enums/PurchaseOptionState.php:26-39`), plus the same accepted-then-rejected `STATE_UNSPECIFIED` (`:45`).

```
DRAFT              → ACTIVE, INACTIVE
ACTIVE             → INACTIVE, INACTIVE_PUBLISHED
INACTIVE           → ACTIVE
INACTIVE_PUBLISHED → ACTIVE
```
(`PurchaseOptionState.php:55-63`.) Enforced in `PurchaseOptionLifecycleService::applyStates()` (`:66-184`), 409 at `:102-111`.

Two side effects of an option state change that an integrator can observe: colliding `legacyCompatible` active options produce **409 `AMBIGUOUS_LEGACY_OPTION`** (`:140-163`), and the legacy price projection is re-run per touched product (`:173`).

`PurchaseOptionState::isDeletable()` is `DRAFT` only (`:128-131`) — and its docblock corrects an earlier claim: **this is our rule, stricter than Google**, which imposes no state restriction on `purchaseOptions.batchDelete` (`:84-93`).

### 2.5 Sellability — two gates, read-time only

`$offer->state->isSellable() && $offer->isWithinSchedule($now)` (`OneTimeProductCatalogService.php:223-224`); `isSellable()` is `=== ACTIVE` (`OfferState.php:108-111`). Option level: `state === ACTIVE && offers->isNotEmpty()` (`:244-245`). Product level: `status === ACTIVE`, else `PRODUCT_NOT_FOUND` (`:159`, `:162`).

Schedule window: `start_time` **inclusive**, `end_time` **exclusive** — deliberate (`app/Models/Offer.php:129-153`, rationale `:121-123`). Null bounds are independent; no bounds means always sellable (`:152`).

Console reads are deliberately **ungated** — no state and no schedule filter, because an operator must be able to see a draft or mispriced product in order to fix it (`OneTimeProductCatalogService.php:116-128`).

**No sellability gate runs at purchase creation.** The only purchase-time rejection is the per-buyer redemption limit (§3.3). The safety argument is structural: the only `offer_token` minter is fed only by the gated read path (`OfferIdentityResolver.php:194-203`).

---

## 3. Dependency Analysis

### 3.1 What this documentation depends on

- **`web-product-service-laravel` @ `origin/staging`** — the only source of truth. Not a build dependency; a factual one. Every number in the docs must be traceable to it.
- **Google's Android Publisher V3 reference** — every page cites it via `Adapted from:`. The repo's job is to describe where Appning agrees with Google and where it does not.
- **Google's discovery document** `androidpublisher.v3.json` rev 20260204, bundled inside `appning-api-python-client`, is what the source repo used to derive its accepted-key allow-lists — and it was cross-checked against *this* documentation repo (`BatchUpdateItem.php:205-211`). So the two repos already reference each other; PAY-1888 (D1) is the other half.
- **`appning-documentation`** — consumes this repo at deploy. No code change needed there (§2.1).

### 3.2 Version and compatibility constraints

- API version segment: `8.20240517` is the value in current examples and in both OpenAPI specs' `info.version`. The segment must match `8.` + exactly 8 digits (`StripApiVersionPrefix.php:39`).
- Two environments are published in the specs: production `https://product.faa.faurecia-aptoide.com/api` and **sandbox** `https://product-sandbox.faa.faurecia-aptoide.com/api`. The current documentation names only production.
- Rate limits (`app/Providers/AppServiceProvider.php:183-235`): `global` 120/min, `auth` 20/min, `catalog` 20/min default but 600/min for a broker-issued token (`:234-235`). None of this is currently documented.

### 3.3 Health of the claims being documented — the three ticket assertions re-tested

| Ticket claim | Verdict | Evidence |
|---|---|---|
| Caps `PURCHASE_OPTIONS_MAX=100`, `OFFERS_PER_OPTION_MAX=100`, `REGIONAL_CONFIGS_MAX=400`, `REDEMPTION_LIMIT_MAX=50` are enforced but undocumented | **Confirmed** | `BatchUpdateItem.php:118`, `:120`, `:122`, `:195` |
| `purchaseOptions[].type` is an accepted Appning field whose disagreement with Google's union is asymmetrically validated | **WRONG at this commit** | `type` is **rejected on key presence** with a message pointing at the union (`:1234-1240`, ADR-0135). Neither half of the asymmetry survives. The ticket's line citation (`one-time-products.md:586-603`) is also wrong — that range is about pre-order `CANCELLED`; the union text is at `:674-691` and is itself stale |
| `redemptionLimit`, `new_regions_config`, `multi_quantity_enabled` are stored but not enforced | **One-third wrong** | `redemptionLimit` is now **enforced at purchase time** (`RedemptionLimitGuard.php:209-214` → 403), landed in the branch-tip commit. `newRegionsConfig` and `multiQuantityEnabled` are confirmed stored-only |

**`redemptionLimit` — the precise current behaviour**, because it is easy to overstate:

- Write time: range check only, `0` (unlimited) or `1..50` (`BatchUpdateItem.php:2025-2034`), accepted only inside `offers[].discountedOffer`.
- Purchase time: `RedemptionLimitGuard::assertWithinLimit()` inside the purchase transaction (`ApplicationPurchaseService.php:158`). Counts prior redemptions under a transaction-scoped Postgres advisory lock keyed on `(buyer, product, purchaseOptionId, offerId)` (`AdvisoryLock.php:167-173`); `count >= limit` → 403 `NotAllowed` (`RedemptionLimitGuard.php:209-214`). Counting rule (ADR-0160): a purchase counts unless voided or its latest order is `REFUNDED`/`CHARGEDBACK`/`CANCELED`; a purchase with no orders **does** count, because the alternative fails open (`RedemptionCountRule.php:96-109`).
- **Two caveats stated in the code itself** (`RedemptionLimitGuard.php:35-55`): it short-circuits when no offer row exists (the dual-read fallback synthesises offers in memory), and it short-circuits when no `offer_token` arrives. Both are true today, so the control is **dormant**.
- **It is explicitly not a security control** (`:24-33`): a caller that omits `offer_token` stays out of the count. ADR-0158 §2 forbids fixing that by rejecting unresolvable tokens.

`newRegionsConfig`: accepted (`:420`, parsed `:1406-1466`, all-or-nothing when present, `:1374-1377`), persisted to three columns (`EloquentProductRepository.php:829-831`), served for round-trip parity only — "nothing in this service observes a new region launching, so no pricing decision reads it" (`OneTimeProductResource.php:147-156`). Verdict **STORED-ONLY**.

`multiQuantityEnabled`: accepted (`:260`), must be a real boolean — `"true"` is rejected, never coerced (`:1567-1570`) — persisted (`EloquentProductRepository.php:842`), served with a warning (`OneTimeProductResource.php:119-124`). `purchases` has no quantity column and the charged amount is not multiplied (`BuyOption.php:35-42`). Verdict **STORED-ONLY**. Its sibling `legacyCompatible` **is** enforced (`BatchUpdateService.php:534`, `LegacyPriceProjector.php:219`) — the two flags are not comparable in reach, which is worth saying in the docs.

---

## 4. Integration Points

### 4.1 The complete current endpoint inventory

**Partner / v3 surface** (`envelope:google`):

| Method | Path | Handler | Notes |
|---|---|---|---|
| POST | `androidpublisher/v3/applications/{domain}/oneTimeProducts:batchUpdate` | `BatchUpdateController@update` | the currently documented endpoint |
| GET | same path | `BatchUpdateController@show` | returns `[]`, 200 (`BatchUpdateController.php:36-39`) |
| PUT / DELETE | same path | `@replace` / `@destroy` | 200 no-op, empty body (`:44-55`) |
| GET | `androidpublisher/v3/applications/{domain}/inapp/oneTimeProducts` | `OneTimeProductController@index` | catalogue read |
| GET | `androidpublisher/v3/applications/{domain}/inapp/oneTimeProducts/purchases` | `OneTimeProductPurchaseController@index` | signed purchase history |

The same catalogue and purchases routes are also registered without the `androidpublisher/v3` prefix under `/applications/...`, from shared closures so they cannot drift (`routes/api.php:303-308`).

**Seller / Console surface** — all POST unless stated, all under `sellers/{uid}/inapp/oneTimeProducts`:

| # | Method | Path tail | Handler | Flag |
|---|---|---|---|---|
| 1 | GET | *(collection)* | `OneTimeProductConsoleController@index` | read |
| 2 | GET | `/{productId}` | `@show` | read |
| 3 | GET | `/{productId}/purchaseOptions/{poId}/offers` | `OfferReadController@list` | read |
| 4 | POST | `…/offers:batchGet` | `OfferReadController@batchGet` | read |
| 5 | POST | `:batchUpdate` | `OneTimeProductWriteController@batchUpdate` | write |
| 6 | POST | `/purchaseOptions:batchUpdateStates` | `PurchaseOptionStateController@batchUpdateStatesAcrossProducts` | write |
| 7 | POST | `/{productId}/purchaseOptions:batchUpdateStates` | `@batchUpdateStates` | write |
| 8 | POST | `…/offers:batchUpdateStates` | `OfferStateController@batchUpdateStates` | write |
| 9 | POST | `…/offers:batchDelete` | `OfferStateController@batchDelete` | write |
| 10 | POST | `…/offers/{offerId}:activate` | `OfferStateController@activate` | write |
| 11 | POST | `…/offers/{offerId}:deactivate` | `OfferStateController@deactivate` | write |
| 12 | POST | `/{productId}/purchaseOptions:batchDelete` | `PurchaseOptionStateController@batchDelete` | write |
| 13 | POST | `:batchDelete` | `OneTimeProductWriteController@batchDelete` | write |
| 14 | DELETE | `/{productId}` | `OneTimeProductWriteController@destroy` | write |

All write routes carry `idempotency` middleware. Offer **reads** (#3, #4) are deliberately outside that group, because the middleware's fingerprint excludes the query string and would replay page 1 for every `pageToken` (`routes/api.php:200-204`).

Route ordering is load-bearing and must not be "tidied" in documentation examples: collection before single entity, cross-product before per-product, batch before single-offer, `:batchDelete` before `DELETE /{productId}` (`routes/api.php:193-194`, `:231-234`, `:244-248`, `:290-293`).

### 4.2 Lifecycle endpoint contracts

| Endpoint | Body | Success | Errors |
|---|---|---|---|
| `offers/{offerId}:activate` | **none** (ids in path) | **204**, empty | 404 if the triple does not resolve; 409 `INVALID_STATE_TRANSITION` |
| `offers/{offerId}:deactivate` | none | 204 | same |
| `offers:batchUpdateStates` | `{"requests":[{"offerId","state"}]}`, 1–100 | 204 | 400 on `STATE_UNSPECIFIED`, on `CANCELLED` (dedicated message), on unknown state; 404; 409 |
| `offers:batchDelete` | `{"requests":[{"offerId","productId?","purchaseOptionId?"}]}`, 1–100 | 204 | 400 duplicate target; 400 missing ids when the path segment is `-`; 404; **409 `LAST_OFFER_OF_ACTIVE_OPTION`** |
| `offers:batchGet` | same target shape | **200** `{"oneTimeProductOffers":[…]}` | 400 duplicate/missing; unresolvable offers are **absent, not 404** (`OfferQueryService.php:106-111`) |
| `purchaseOptions:batchUpdateStates` (both variants) | `{"requests":[{"purchaseOptionId","state","productId"}]}`, 1–100 | 204 | 400; 404; 409; 409 `AMBIGUOUS_LEGACY_OPTION` |
| `purchaseOptions:batchDelete` | `{"requests":[{"purchaseOptionId"}]}`, 1–100 | 204 | 400 duplicate; **409 `PURCHASE_OPTION_NOT_DELETABLE`** unless `DRAFT`; unresolvable ids are skipped and the call still succeeds |

`:activate` / `:deactivate` targets are fixed, not caller-supplied, and are implemented as one-item batches through the same service (`OfferStateController.php:61`, `:71`, `:129-148`).

`:cancel` does **not** exist, deliberately — Google's `cancel` targets the pre-order-only `CANCELLED` state and pre-orders are rejected on write (`routes/api.php:256-258`, `OfferStateController.php:36-40`).

Per-product vs cross-product `purchaseOptions:batchUpdateStates`: the per-product variant takes `productId` from the path and **ignores** a body `productId` rather than letting it contradict the URL (`PurchaseOptionStateController.php:41-43`); the cross-product variant **requires** `productId` per item (`PurchaseOptionStatesRequest.php:104-112`). The cross-product variant is a **local extension, not a Google method**.

`offers:list` specifics: `pageSize` default 50, max 1000, **coerced not rejected** (`OfferQueryService.php:48`, `:85`); response always carries `nextPageToken`, null when there is no next page (`OfferReadController.php:63-69`); `-` wildcard accepted on both path ids, but a specific `purchaseOptionId` under `productId: -` is a 400 (`:53`, `:152-162`); every state is returned, `DRAFT` and `INACTIVE` included (`:26-28`).

### 4.3 Google method coverage — the existing "not implemented" list needs care

| Level | Google method | Present? |
|---|---|---|
| product | `list`, `get`, `batchUpdate`, `batchDelete`, `delete` | **Yes** — but `list`/`get`/`batchDelete`/`delete` only on the **Console** surface |
| product | `batchGet`, `patch` | **No** (verified absent from `routes/api.php`) |
| purchaseOptions | `batchUpdateStates`, `batchDelete` | Yes |
| offers | `list`, `batchGet`, `batchUpdateStates`, `batchDelete`, `activate`, `deactivate` | Yes |
| offers | `cancel` | No — deliberate |
| offers | `batchUpdate` | No — `oneTimeProducts:batchUpdate` already writes offers (ADR-0138 status table, `docs/architecture/decisions/0138-offer-lifecycle-state.md:208`) |

**So the current page's `<details>` list of six unimplemented product methods is not simply wrong — it is surface-dependent.** On the `androidpublisher/v3` surface it is still accurate: only `:batchUpdate` is there. Four of the six are now implemented, but on a different surface with a different path, auth model and error envelope. Rewriting the list without saying which surface it describes would replace one inaccuracy with another. This is the single most delicate edit in the ticket, and it directly touches the acceptance criterion "nothing previously correct has been changed without a code check".

### 4.4 Consumers of this contract

- **`appning-api-python-client`** (PAY-1888 / D1) — the generated client and the sibling deliverable. It already bundles Google's discovery document that the source repo derived its allow-lists from.
- **`broker-api` / `web-broker-service`** — the offer-token consumer side. `web-broker-service` PR #213, which would forward `offer_token`, was open, unmerged and undeployed as of 2026-09-03 (`RedemptionLimitGuard.php:35-55`).
- **The Console / Portals front end** — the main writer through the seller surface.

### 4.5 Per-region offer pricing (ADR-0128/0129/0130, PAY-1819/1820/1821)

**Write shape.** An offer's `regionalPricingAndAvailabilityConfigs[]` entry accepts exactly five keys (`BatchUpdateItem.php:312-318`): `regionCode` (required), `availability` (optional, defaults to `AVAILABILITY_UNSPECIFIED`), and **exactly one** of `noOverride`, `relativeDiscount`, `absoluteDiscount`. **There is no `price` key at offer level** — `price` exists only on the option-level config set (`:282-286`). An offer never stores a price, only a per-region modifier. Offers are authored inside `oneTimeProduct.purchaseOptions[].offers[]`; `updateMask` gains no new root (ADR-0130).

**The override union.**

| Member | Type | Rule |
|---|---|---|
| `noOverride` | marker object `{}` | Google's marker type. The signal is **key presence, never value** (`:2230-2232`, `:2271-2275`) |
| `relativeDiscount` | decimal **string**, carried as a string end-to-end, never a float | A **fraction, not a percentage** — `0.2` means 20% off. Strictly `> 0` and `< 1`, both bounds exclusive. Normalised to scale 8 *before* the bound check because the column is `numeric(9,8)` (`:2318`, `:2320`, rationale `:2306-2317`) |
| `absoluteDiscount` | Money `{currencyCode, units, nanos}` | Currency must equal the **base price currency for that same region** (`:2372-2377`); must not exceed that region's base price (`:2390-2396`); `units >= 0`, `nanos` 0–999999999 (`:2384`). Zero is legal and means "no modification" |

Exactly-one is enforced twice: in the DTO, user-facing (`:2245-2268`, messages at `:2255` and `:2263-2264`), and as a database CHECK constraint `offer_regional_configs_variant_ck` as a backstop (`2026_08_15_120000_create_offer_regional_configs_table.php:96-114`).

A region entry **can only name a region the parent option prices** (`:2193-2200`). Region sets are written **delete-then-insert — replace, not merge** (`BatchUpdateService.php:884-896`), and offers absent from a payload are **deleted** (`:853-856`). This is significant for an integrator: a partial offer list silently removes the rest.

**Price computation** — one implementation, pure, no database or config (`app/Services/Offer/OfferPriceResolver.php:23-28`), rule from ADR-0129:

```
discountMicros = round_half_up(baseMicros × fraction)
resolvedMicros = max(0, baseMicros − discountMicros)
```

`baseMicros` = `units × 1_000_000 + intdiv(nanos, 1_000)` (`Money.php:74-77`). All arithmetic is bcmath — no float appears anywhere (`OfferPriceResolver.php:126-133`). **The discount is clamped, not the resolved price** (`:59-68`), which keeps `base − discount = resolved` exact; a later price-only write can lower a base below an already-stored discount. A null config for a region means the base price unchanged, which is Google's definition (`:50-53`).

When a config declares a discount variant but carries no usable value, the resolver charges **full price** — never undercharging — and the read surface logs `offer.regional_config_unusable` at warning level rather than serving the contradiction silently (`OneTimeProductResource.php:363-376`).

**Three prices in one response, easily confused** — a documentation hazard:

| Field | Meaning |
|---|---|
| per-region `base_price` / `resolved_price` | the authoritative pair |
| `offers[].price` | the **payable** amount; when the flat block is projected it is `full_price_micros − discount.amount.micros`, because emitting `price_micros` unchanged once made a client collect the undiscounted amount (`OneTimeProductResource.php:177-217`) |
| `offers[].discount` | **projected on read** for unmigrated clients, and **lossy by design** — one amount and one currency cannot express a per-region offer, so it reports the offer's own currency, first region in sorted order (`:554-575`) |

**Read shape per region** (`OneTimeProductResource.php:378-395`): `region_code`, `availability`, `pricing_variant`, `relative_discount`, `absolute_discount`, `base_price`, `resolved_price`. Money envelope is `{currency, value, label, symbol, micros}` (`:505-517`). Entries are sorted by `region_code`.

**The Console offers list is deliberately leaner** — `region_code`, `availability`, `pricing_variant` only, no discounts and no prices, because the wildcard forms span products (`OfferReadController.php:103-133`).

**The option-level config set is not serialised on any read surface.** `shapeOption()` emits `purchase_option_id`, `buy_option`, `rent_option`, `offer_tags`, `new_regions_config`, `withdrawal_right_type`, `offers` and nothing else (`OneTimeProductResource.php:96-170`). A client sees an option's base price only indirectly, through each offer entry's `base_price`. The write path does echo the option configs back in the `:batchUpdate` response (`BatchUpdateService.php:1122-1141`).

**Availability — two enums, three vs four values, and a client obligation.**

- Offer level, `OfferAvailability`: `AVAILABILITY_UNSPECIFIED`, `AVAILABLE`, `NO_LONGER_AVAILABLE` (`app/Enums/OfferAvailability.php:20-25`).
- Option level, `ProductPriceAvailability`: adds `UNAVAILABLE`, which is **ours, not Google's** (`app/Enums/ProductPriceAvailability.php:7-13`, `PurchaseOptionRegionalPrice.php:23-28`).

`NO_LONGER_AVAILABLE` hides the **offer** for a region, not the product — the buyer still sees the product at base price (`OfferAvailability.php:16-18`). **Nothing in the read path filters on offer availability**: the region is served with its prices intact, so hiding it is a **client obligation** (`OneTimeProductResource.php:341-342`). Option-level availability is not filtered on the v8 read either (`:455-461`). Availability filters in exactly one place: the dual-read fallback, which projects offers only from `STANDARD` + `AVAILABLE` country prices (`OneTimeProductCatalogService.php:318-335`).

**EEA display rule** — in ten (digital content) or eleven (digital services) named EEA regions the buyer must see only the discounted price, with no strikethrough. Both `base_price` and `resolved_price` are returned so a Console can show a seller what each region pays. **Nothing in the service enforces this**; which list applies is given by the option's `withdrawal_right_type` (`docs/api/v8-one-time-products.openapi.yaml:83-99`).

### 4.6 `offer_token` (ADR-0136, corrected by ADR-0139; ADR-0149/0158/0159)

**What it is.** A token naming one offer on one purchase option of one product. Derived on every read, never read from storage.

```
otk_ + base64url(HMAC-SHA256(OFFER_TOKEN_SECRET, "{productUid}|{purchaseOptionId}|{offerId}"))[0..32]
```

(`app/Support/Offers/OfferToken.php:86-96`.) Total length **36 characters**, format `/^otk_[A-Za-z0-9_-]{32}$/`. The three inputs are the **public string ids**, never database primary keys — the dual-read fallback synthesises options and offers in memory with no keys, so keys would leave every un-backfilled product tokenless (`:28-44`).

**Not reversible.** A truncated one-way HMAC. There is no `verify()` and no `parse()` (`OfferIdentityResolver.php:20-30`); resolution can only recompute candidates and compare with `hash_equals` (`:273-282`).

**The trust model, which the documentation must state accurately.** The broker never verifies a signature. It matches the token against a catalogue response **it fetched itself**. Trust comes from the catalogue being the price authority, not from cryptography — the HMAC buys unguessability, not authority (`OfferToken.php:20-26`). The token carries **no expiry**; freshness of the catalogue read is the expiry mechanism (`:64-66`).

**Where it appears.**

| Surface | Carries `offer_token`? |
|---|---|
| Buyer catalogue `GET .../inapp/oneTimeProducts` | **Yes** — `…purchase_options[].offers[].offer_token` |
| Console product detail `GET .../sellers/{uid}/inapp/oneTimeProducts/{productId}` | **Yes** (reuses the buyer subtree) |
| Console product list | No — summary resource, counts only |
| Console `offers` list and `offers:batchGet` | **No** (`OfferReadController.php:114-133`) |
| Purchase history read | No |

Minted at exactly one place (`OneTimeProductResource.php:246`), unconditionally, so persisted and fallback-synthesised offers both carry it. **Inbound**, it is accepted as a top-level body field on purchase-create (`POST {domain}/inapp/consumables/{sku}/purchase`, `POST {domain}/paidapps/purchases`) with the rule `nullable|string|max:64` (`ApplicationPurchaseInput.php:159`) — note that rule *is* the acceptance mechanism, since `validated()` returns only keys that have a rule (`:146-150`). The rule is deliberately weak — no prefix or charset check — because a 400 maps to a PERMANENT broker outcome that would leave an already-charged transaction short of `COMPLETED` (`:152-158`).

**The intended client flow, in two halves.**

*Half 1 — price resolution, done by the broker (ADR-0139):* the client holds the catalogue response and therefore the token; it sends the token with the purchase request; the broker **re-reads the catalogue itself** (`GET .../inapp/oneTimeProducts?productIds[]={sku}` with its own service JWT), flattens `oneTimeProducts[].purchase_options[].offers[]`, compares `offer_token` with `===`, and reads the decimal `price.value` + `price.currency`. Key rules an integrator must know:

- **Read `price.value`, never `price.micros`** — the broker's money type is 10^8 and this service emits 10^6, so reading micros mis-prices by 100× (ADR-0139 §5).
- **Parse `price.value` as a decimal; do not assume two decimal places** — trailing zeros are trimmed, so 5000000 renders as `"5"` (`Money.php:96-105`).
- **There is no token-lookup endpoint and none will be built.** `productIds[]` with a single id *is* the single-product read (ADR-0139 R2).
- **Cache nothing across requests** — one fresh read per transaction; the route sits deliberately outside the response-cache group (`routes/api.php:453-466`).
- **Fail closed** — an unresolvable token must reject the purchase, never fall back to a client-supplied price (ADR-0139).
- **One buyer-facing message** — "this offer just ended" and "this token is false" are indistinguishable by construction, so both resolve to "the offer is not available".
- Timeout budget: connect 1s, total 2s, one retry on transport error or 5xx, **never on 4xx**.
- Rate limit: the catalogue group uses issuer-aware `throttle:catalog` — 600/min for a broker token, 20/min otherwise (`config/security.php:104`, `:114`).

*Half 2 — offer identity on the purchase (ADR-0158/0159):* the broker forwards the token; `OfferIdentityResolver::resolve()` turns it into `(purchaseOptionId, offerId)` by **bounded recomputation** (`:99-175`) — persisted candidates from one lean two-column join, deliberately **unfiltered by state and schedule** because the question is "what was this buyer charged against", which does not expire (`:180-188`); if rows exist and none match, the answer is null with **no fallback** (`:154-166`). **This resolver never throws and never rejects** — the card is already charged, and a 4xx would take money without granting entitlement (`:32-38`). The identity is stored as two nullable `varchar(191)` public string columns on `purchases`, not foreign keys, because a fallback purchase has no rows to point at. Subscriptions resolve to null by design.

**State of the flow today.** The resolution half is merged in `broker-api` on `main` but gated by `v8-offer-token-strict`, which **defaults to false**; the legacy broker holds no resolution code at all and returns 422 for every real token. **No shipped broker forwards `offer_token` in an outbound body to this service.** A code comment naming the broker's `V8::BODY_FIELD_OFFER_TOKEN` refers to a constant that does not exist in either broker repository.

**What ADR-0139 corrected in ADR-0136** — three statements plus a reference, all applied inline in ADR-0136 (`0136-...md:3`, `:95-134`):

1. "The broker's price check now actually engages" — **it does not**; the legacy broker returns 422 for every real token and the flag never runs.
2. "Before this, the client-supplied price was used" — **a price check does exist and run**, but it reads the **wrong endpoint** (`.../inapp/consumables/`, which returns one price and cannot show an `offers[]` array), so for a multi-offer product it compares against the wrong offer. That is the real defect, and it differs from the one ADR-0136 describes.
3. The offer-schedule interaction date is 2026-08-19, not 2026-08-18.
4. The cited `resolveOffer()` branch name was wrong — cite `origin/main`, not a merge branch.

ADR-0139 was itself partly corrected by ADR-0149 on three supporting statements — including one whose stated *reason* was wrong while its substance stood. **Three ADRs in a chain, each correcting the last, is the strongest possible argument for citing code rather than decision records.**

---

## 5. Risk Assessment

### 5.1 Highest risk — documenting endpoints that may not answer

Both Console flag groups **default to `false`** (`config/services.php:119-129`), and the flags gate at *route registration*, so a disabled surface **404s** rather than returning a meaningful error. `.env.example` contains no entry for either flag, so their live values are deployment configuration that is not in the repository and could not be verified here.

The source repo states the principle itself, about a different endpoint: "publishing a contract for an endpoint that 404s is worse than omitting it" (`docs/api/v8-one-time-products-console.openapi.yaml`, "Not in this spec"). Documenting all eleven Console endpoints while they are switched off in production would breach that principle and this repository's own "not implemented" convention. **This must be resolved before writing, not during review.** It is the main open decision (§7.2).

### 5.2 Repeating the failure the ticket exists to fix

The ticket's own three substantive claims were tested and **two are wrong** (§3.3). Both wrong claims came from prose — an audit summary and stale in-repo docblocks — not from code. If any statement is copied from the ticket, an ADR or an architecture note without a code check, the update will publish a fresh inaccuracy into a document whose whole value is that it had none.

### 5.3 Attributing our own limits to Google

`BatchUpdateItem.php:78-88` carries an explicit warning under the heading "**These are OURS, not Google's — do not cite them as Google limits**", covering `PURCHASE_OPTIONS_MAX`, `OFFERS_PER_OPTION_MAX` and `REGIONAL_CONFIGS_MAX`. It records that this repository "has already shipped a validator that rejected input Google accepts because a number from our own design was recorded as Google's (the `redemptionLimit` 1–50 incident, ADR-0134)". `RentalPeriodMatrix.php:14-33` carries the same correction for the rental matrix, noting an earlier docblock asserted a Google API fact that is not one.

Since every page in this repository opens with `Adapted from:` and a Google URL, the format actively invites this mistake. Provenance labelling is therefore a **required** design element, not a nicety. The caps that genuinely are Google's, quoted in code, are `REDEMPTION_LIMIT_MAX` 1–50 (`:181-183`), the 20-character tag content limit (`:143-146`), the 63-character id limit (`:482-485`), and the combined 100 options-and-offers ceiling (`BatchUpdateService.php:56-58`).

### 5.4 Surface conflation

Documenting Console endpoints alongside the v3 method without separating the two surfaces would attach the wrong auth model, the wrong error envelope and the wrong pagination shape to real endpoints. An integrator following it would parse `{code,path,text,data}` as `{"error":{…}}`, or expect `seller.acl` scoping on a package-scoped route.

### 5.5 Documenting a dormant control as a live one

`redemptionLimit` is enforced in code and inert in practice, behind two independent gates, and is explicitly not a security control. Writing "the server enforces up to 50 redemptions per buyer" full stop would be true of the code and false of the running system, and could be read as a security guarantee it does not provide.

### 5.6 Documenting an integration flow nobody has wired yet

The `offer_token` client flow (§4.6) is fully implemented on the producing side and **not in use on the consuming side**: the broker path is merged but flag-gated to `false`, the legacy broker rejects every real token, and no shipped broker forwards the token to this service. Publishing "send `offer_token` with your purchase request and the server will resolve it" as present-tense fact would describe a path that currently does nothing for an external integrator. The flow is still worth documenting — the ticket asks for it — but tense and status must be exact.

### 5.7 Both OpenAPI specs are themselves stale — they cannot be used as a shortcut

It is tempting to transcribe the source repo's OpenAPI specs instead of reading code. Four verified drifts say otherwise:

1. `offer_token` is declared `nullable: true` with the description "null until minted in a later phase" (`v8-one-time-products.openapi.yaml:663-666`, and `-console.openapi.yaml:1499` plus a `null` example at `:232`). The code mints it unconditionally on every read.
2. The buyer `Offer` schema omits `state`, `discounted_offer` and `regional_pricing_and_availability_configs`, all of which the code emits (`:658-699` vs `OneTimeProductResource.php:234-270`).
3. The buyer `PurchaseOption` schema still requires `type`, `rental` and flat `legacy_compatible` / `multi_quantity_enabled` (`:562-565`, `:641-642`) — a generation behind the union the code emits.
4. The write schema defines only `purchaseOptionId` and `regionalPricingAndAvailabilityConfigs` on a purchase option, omitting `offers[]`, `buyOption`, `rentOption`, `newRegionsConfig`, `taxAndComplianceSettings`, `offerTags`, `discount` and `timeWindow` (`:904-938` vs `BatchUpdateItem.php:416-439`).

In each case the same file's **prose description** is correct while its **schema** is stale — so even within one spec the two halves disagree. The Console spec is drift-guarded only for *route presence*, not for schema accuracy. Treat both specs as cross-references, never as sources.

### 5.8 Lower risks

- **No automated verification exists** in this repository, so nothing will catch a drifted number later. The Console OpenAPI spec has a drift test; these Markdown pages have nothing.
- **The buyer/v3 OpenAPI spec has no drift guard** and is documented as needing manual checks — so it is a useful cross-reference but not an authority. Only code is.
- **`{purchaseOptionId}` in real data**: multi-option is live in code, but `RedemptionLimitGuard.php:35-55` states `purchase_options` and `offers` held zero rows in staging and production as of the 26 August audit. Examples should not imply a populated catalogue.
- **No performance, migration or data-consistency risk** — this change ships Markdown only.

---

## 6. Prior Art & Ecosystem Research

### 6.1 The pattern this repository already follows

Google's own Android Publisher reference is the model: one page per method, one per resource, one per schema/enum, with a fields list carrying type, cardinality and constraints. The repository is an explicit local re-organisation of it. Google's REST reference also has an established way of expressing exactly the two things this update needs:

- **Union fields** — Google names the union and lists its members ("Union field `purchase_option_type`. Exactly one must be set"). The existing resource page already uses this shape for `buyOption`/`rentOption`, so the new pricing-override union has a precedent to copy verbatim.
- **`output only` / `immutable` / `required` markers** on fields, which the existing pages already use.

### 6.2 How the source repo documents divergence — the strongest precedent

`web-product-service-laravel` maintains numbered divergences (D-1, D-3, D-4 …) and ADRs, and its OpenAPI descriptions state divergences inline and in tables, for example the buyer-vs-console visibility table in the Console spec header. Two habits are worth adopting directly:

1. **Say what is ours.** Every locally-invented field, cap and rule is labelled in code as `OURS`, `TOLERATED` or `SPECIFIC` (`BatchUpdateItem.php:370-390`). A documentation equivalent — marking each field as Google's, Appning's, or accepted-but-inert — would carry the same information to an integrator.
2. **Say when we are stricter and why.** The rental matrix and the `DRAFT`-only delete rule are both stricter than Google, and both docblocks insist the rule be kept but not cited as parity.

### 6.3 Known pitfall, observed repeatedly in this very codebase

**Prose in this ecosystem lags its own code.** Verified stale claims at `c4dd77a`:

| Location | Stale claim |
|---|---|
| `docs/architecture/one-time-products.md:674-691` | "We keep the field", the type/union "can disagree", and the "known asymmetry, deliberately left" paragraph — all three now false |
| `docs/architecture/one-time-products.md:123-126` | `type` accepted with `rentalPeriod` required iff `type == RENTAL` |
| `app/Enums/PurchaseOptionType.php:18-26`, `BuyOption.php:19-24` | `buyOption`/`rentOption` "must AGREE with" `type` |
| `BatchUpdateItem.php:1204-1209`, `:1477-1495`, `:1994-1998` | `type` defaults to `ONE_TIME`; the two "can disagree"; `redemptionLimit` enforcement "is not implemented" |
| `routes/api.php:250-254` | `{purchaseOptionId}` can only hold `default` |
| `docs/architecture/one-time-products.md:420-421` | the base price "stays authoritative" in `product_prices_country` — contradicted by `:472-481` of the same file, and by the code |
| `app/Services/AndroidPublisher/BatchUpdateService.php:819-820` | the base price "stays on the purchase option, in `product_prices_country`" — two clauses that cannot both be true; ADR-0150 flagged this exact sentence and it was never removed |
| `app/Dto/Internal/Purchase/ApplicationPurchaseInput.php:142` | cites the broker's `V8::BODY_FIELD_OFFER_TOKEN` — **no such constant exists** in either broker repository |
| both OpenAPI specs | four schema drifts, §5.7 |

The same document contradicts itself: `one-time-products.md:38-45` and `:645` state the correct, current rule while `:674-691` states the retired one. Two independent research agents reached opposite conclusions on the `rentOption`-on-`ONE_TIME` question purely from which of these two sources they read — one followed the docblock at `:1488-1495`, the other followed the parser at `:1242-1269`. The parser wins, but the episode is the clearest possible demonstration of the pitfall.

**Anti-pattern to avoid:** citing an ADR or a docblock as evidence. Cite the parser, the enum, the route or the migration.

---

## 7. Recommendations

### 7.1 Suggested approach

**Restructure by surface, then fill.** Recommended over patching the two existing pages in place.

```
docs/appning/android-publisher/monetization.onetimeproducts/
  README.md                          (extend: structure + covered sub-links)
  batchUpdate.md                     (extend: caps, unknown-key rejection, updateMask lists, offers[])
  monetization.onetimeproducts.md    (extend: offers[], the pricing union, provenance + enforcement markers)
  offers/                            (new — the offer resource and its lifecycle)
    offers.md                        (resource + OfferState + transitions)
    activate.md  deactivate.md  batchUpdateStates.md  batchDelete.md  batchGet.md  list.md
  purchase-options/                  (new)
    batchUpdateStates.md  batchDelete.md
  types/                             (new pages, existing pattern)
    offer-state.md  purchase-option-state.md  offer-availability.md
    offer-pricing-variant.md  relative-discount.md  absolute-discount.md
```

Rationale: it preserves the one-page-per-method convention the repository and Google both use; new files appear in the portal navigation automatically; and the directory split is what keeps the two surfaces from blurring.

Alternative considered — a single long "what changed since March 2026" page. Rejected: it fights the repository's structure, ages badly, and the ticket explicitly says to keep the existing organisation.

**Three cross-cutting devices to introduce, each justified by a §5 risk:**

1. **A surface preamble** on every page: path shape, auth, error envelope, and pagination. Directly mitigates §5.4.
2. **A provenance marker per field and per cap** — Google's / Appning's / accepted-but-inert. Mitigates §5.3 and satisfies the "stored but not enforced" acceptance criterion in one mechanism rather than two.
3. **An enforcement column, not a prose aside**, for caps: value, where enforced, and whose rule it is.

### 7.2 Decisions needed before design

1. **Do the Console endpoints get published while both feature flags default to `false`?** (§5.1) Options: document them normally; document them behind an explicit availability note; or list them in the existing `<details>` "not implemented" style until the flags are confirmed on. **Recommendation:** ask the ticket reporter or the Payments team for the deployed flag values, and default to an explicit availability note rather than silence — this cannot be decided from the repository.
2. **How is the "six methods not implemented" list rewritten** so it stays true for the v3 surface while acknowledging the Console surface? (§4.3) **Recommendation:** keep the list, scope it explicitly to the v3 surface, and link to the Console pages — do not delete it.
3. **Does the buyer catalogue surface** (`GET .../inapp/oneTimeProducts` and `.../purchases`) come into scope? It shipped in the same period, is partner-facing, and is entirely undocumented here — but the ticket does not ask for it. **Recommendation:** out of scope for PAY-1889; raise it as a follow-up so it is not lost.
4. **How much of `redemptionLimit`'s dormancy to publish?** (§5.5) **Recommendation:** state the write-time range, state that enforcement happens at purchase time, and state plainly that it is a merchandising control and not a security control. Do not publish internal deployment state such as "staging has zero rows".
5. **Sandbox base URL and rate limits** — both are absent from the current documentation and both are things an integrator needs. **Recommendation:** add; low cost, high value.
6. **In what tense is the `offer_token` flow documented?** (§5.6) The producing side is live; no consumer forwards the token. **Recommendation:** document the token, its format, where it appears and what it means as present fact — that is all true — and describe the purchase-time resolution as the defined contract, with an explicit note that no broker forwards it yet. Do not publish the internal flag name or deploy state.

Also worth carrying into the pages, since each is a behaviour an integrator will otherwise learn by accident: offer and region sets are **replace-not-merge** (an omitted offer is deleted); `NO_LONGER_AVAILABLE` at offer level is served with prices intact and hiding it is a **client obligation**; the EEA no-strikethrough rule is likewise unenforced by the service; and `offers[].discount` is a **lossy projection** for unmigrated clients rather than an authoritative field.

### 7.3 Unknowns to resolve

- Deployed values of `V8_OTP_CONSOLE_READ` / `V8_OTP_CONSOLE_WRITE` — **not answerable from the repository** (blocks decision 1).
- The audit artefacts the ticket cites as evidence, `05-batch-update.md` and `08-divergences.md`, are **not present** in any local repository; searched `api-documentation`, `web-product-service-laravel` (including `docs/audit/`), and `appning-documentation`. If the six-method list came from there, the reasoning behind it cannot be checked. Worth requesting.
- Whether PAY-1888 (D1) intends to link to specific page paths in this repository — if so, the page layout in §7.1 must be agreed with that ticket before either lands.
- Deployed value of the broker flag `v8-offer-token-strict` (defaults to `false` in both broker repositories) and whether `web-broker-service` PR #213 has merged — both determine whether the `offer_token` flow described in §4.6 is live for anyone. **Not answerable from any repository.**
- Whether `OFFER_TOKEN_SECRET` is set in staging, sandbox and production. A readiness gate exists to catch an unset value (`HealthReadyController.php:125-171`), but deploy state is not in the repository.
- The measured p99 of the single-SKU catalogue read. ADR-0139 requires it to be measured before any latency target is accepted; no measurement exists in the repository. **Do not publish a latency figure.**

### 7.4 Next step

`/design-system update-onetimeproducts-docs` — after decisions 1, 2 and 6 in §7.2 are answered.
