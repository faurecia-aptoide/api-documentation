# Project Spec: update-onetimeproducts-docs

**Issue:** PAY-1889 · **Phase:** 3 (Design) · **Date:** 2026-09-03

---

## 1. Technical Requirements

Derived from `01_DISCOVERY.md` success criteria, adjusted where research contradicted the ticket (TR-06, TR-07).

| ID | Requirement | Verification |
|---|---|---|
| **TR-01** | Every cap enforced at write time appears with the same number as the code, in a per-method enforcement table: batch items 100, purchase options 100, offers/option 100, regional configs/option 400, options+offers combined 100, offer tags 20, tag content 20 chars, ids 63 chars, title 55, description 200, `redemptionLimit` 0 or 1–50 | Ledger row per cap; number matches source |
| **TR-02** | Each cap states **whose rule it is**. The three array caps (100/100/400) are marked **Appning**, not Google | Provenance column filled for every cap |
| **TR-03** | The combined options+offers ceiling documents its **non-regression** behaviour: an over-limit product still accepts a write that does not increase the count, returning a warning | Ledger row |
| **TR-04** | The per-region offer pricing model is documented: `regionalPricingAndAvailabilityConfigs[]` per offer, exactly one of `noOverride` / `relativeDiscount` / `absoluteDiscount`, with `relativeDiscount` stated as an exclusive-bounds **fraction** (not a percentage) | Contract §3.2 transcribed; both union error messages listed |
| **TR-05** | The offer resource, `OfferState`, its three transitions, and all six lifecycle endpoints are documented, each with body, success status and error cases | One page per endpoint; ADR-003 marker present |
| **TR-06** | `offer_token` is documented per ADR-006: format, derivation, non-reversibility, no expiry, which responses carry it, and the client rules — split into "what it is" and "how it is used" | ADR-006 registers respected; no internal identifiers |
| **TR-07** | Purchase-option state transitions are documented, both the per-product and cross-product `:batchUpdateStates` variants, including that body `productId` is ignored on one and required on the other | Both variants on one page |
| **TR-08** | The Appning-only `type` field is documented **as rejected**, not as a conflicting field. The ticket's asymmetry claim is not published — the code contradicts it | Ledger status `rejected` for the ticket claim; page states current behaviour |
| **TR-09** | Fields accepted but not enforced are marked **Accepted, not enforced**: `newRegionsConfig`, `multiQuantityEnabled`. `redemptionLimit` is **not** in this list — it is enforced at purchase time | Provenance markers; `redemptionLimit` documented per TR-10 |
| **TR-10** | `redemptionLimit` is documented as: Google's 1–50 range checked on write, counted **per buyer at purchase time** (403 when at cap), and explicitly a merchandising control, **not** a security control | Ledger row; wording reviewed |
| **TR-11** | The "not implemented" list is scoped per surface and cross-linked per ADR-004 | Page diff reviewed against ADR-004 |
| **TR-12** | Every page carries a surface preamble: path shape, auth, error envelope, pagination | Present on all new and modified pages |
| **TR-13** | Replace-not-merge write semantics are documented on both the method and resource pages: omitted offers are deleted; region sets are delete-then-insert | Ledger row |
| **TR-14** | Client obligations the service does not enforce are stated: offer-level `NO_LONGER_AVAILABLE` is served with prices intact and must be hidden by the client; the EEA no-strikethrough rule is unenforced; `offers[].discount` is a lossy projection for unmigrated clients | Ledger row each |
| **TR-15** | Both index lists are updated: the section `README.md` structure + covered sub-links, and the root `README.md` endpoint table | File tree matches both lists exactly |
| **TR-16** | No existing page is moved or renamed; no existing correct statement is changed except per ADR-004 | `git diff --stat` shows no renames; TR-11 is the only certified-text change |
| **TR-17** | Sandbox base URL and the issuer-aware catalogue rate limits are documented | Ledger row |
| **TR-18** | Every published claim has a ledger row citing `file:line` at `c4dd77a`; no page ships a `pending` claim | `04_CLAIM_LEDGER.md` complete |

---

## 2. Non-Functional Requirements

Measurable, and checkable without running anything.

| ID | Requirement | Target | How measured |
|---|---|---|---|
| **NFR-01** | Claim coverage | **100%** of published numeric caps, enum vocabularies, status codes and error codes have a ledger row | count ledger rows vs claims per page |
| **NFR-02** | Page weight | ≤ 40 KB per page; ≤ 500 lines | `wc -c`, `wc -l` |
| **NFR-03** | Internal-identifier leakage | **zero** occurrences of `.php`, `ADR-0`, `V8_OTP_`, `origin/staging`, a commit hash, or a `database/` path in any published page | `grep -rE` over `docs/` and `README.md` |
| **NFR-04** | Relative-link validity | **zero** broken relative links; every link target resolves to a file that exists | link-check script (§4) |
| **NFR-05** | Index completeness | file tree ≡ section `README.md` lists; every endpoint page appears in the root endpoint table | diff generated list vs committed list |
| **NFR-06** | Navigation depth | ≤ 2 directory levels below `monetization.onetimeproducts/` | tree inspection |
| **NFR-07** | Portal render safety | pages use only CommonMark plus the `<details>`/`<summary>` and `<a href>` HTML already present in the repo; no new HTML constructs, no scripts, no images | grep for tags not already used |
| **NFR-08** | Structural consistency | every new page carries, in order: `# <Kind>: <name>`, `Adapted from:`, surface preamble, body, `## Local references` | per-page checklist |
| **NFR-09** | Terminology consistency | one term per concept across all pages (e.g. always "purchase option", never "option" alone in a definition) | review pass |
| **NFR-10** | Accessibility | no information conveyed by colour or emoji alone; every table has a header row; provenance markers are readable words, not symbols | review pass |
| **NFR-11** | No unmeasured performance claims | zero latency or throughput figures beyond those Google publishes for `latencyTolerance` | grep for `ms`, `p99`, `per second` |

---

## 3. Interface Contracts

These are the wire shapes to be transcribed onto pages. Types are given precisely so the pages cannot drift from the parser. `?` marks optional; `| null` marks nullable in responses.

### 3.1 Enum vocabularies (complete, closed sets)

```ts
type OfferState            = 'DRAFT' | 'ACTIVE' | 'INACTIVE';                       // 3 — CANCELLED not modelled
type PurchaseOptionState   = 'DRAFT' | 'ACTIVE' | 'INACTIVE' | 'INACTIVE_PUBLISHED'; // 4
type OfferAvailability     = 'AVAILABILITY_UNSPECIFIED' | 'AVAILABLE' | 'NO_LONGER_AVAILABLE';           // 3, offer level
type OptionAvailability    = 'AVAILABILITY_UNSPECIFIED' | 'AVAILABLE' | 'UNAVAILABLE'                    // 4, option level;
                           | 'NO_LONGER_AVAILABLE';                                                      //   UNAVAILABLE is Appning's
type OfferPricingVariant   = 'NO_OVERRIDE' | 'RELATIVE_DISCOUNT' | 'ABSOLUTE_DISCOUNT';                   // read side
type LatencyTolerance      = 'PRODUCT_UPDATE_LATENCY_TOLERANCE_UNSPECIFIED'                               // LATENCY_SENSITIVE
                           | 'PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT';                         //   is NOT accepted
type WithdrawalRightType   = 'WITHDRAWAL_RIGHT_TYPE_UNSPECIFIED' | 'WITHDRAWAL_RIGHT_DIGITAL_CONTENT'
                           | 'WITHDRAWAL_RIGHT_SERVICE';
```

`STATE_UNSPECIFIED` is accepted at the request boundary and then rejected for both state enums — document as "must not be sent", not as a value.

### 3.2 Write: an offer inside `:batchUpdate`

```ts
interface OfferWrite {
  offerId: string;                              // /^[a-z0-9][a-z0-9-]{0,62}$/ — Google's grammar
  discountedOffer: DiscountedOffer;             // exactly one of discountedOffer | preOrderOffer;
                                                //   preOrderOffer is recognised and rejected
  offerTags?: OfferTag[];                       // tri-state: absent = inherit, [] = clear, [...] = set
  regionalPricingAndAvailabilityConfigs?: OfferRegionalConfig[];   // no count cap at this level
}

interface DiscountedOffer {
  startTime?: string;                           // RFC 3339
  endTime?: string;                             // RFC 3339, must be later than startTime
  redemptionLimit?: number;                     // 0 (unlimited) or 1..50
}

interface OfferRegionalConfig {
  regionCode: string;                           // ISO 3166-1 alpha-2 (uppercase) or UN M.49 numeric-3;
                                                //   stored and echoed verbatim, never canonicalised;
                                                //   must already be priced on the parent option
  availability?: OfferAvailability;             // default AVAILABILITY_UNSPECIFIED
  // exactly one of the following three:
  noOverride?: Record<string, never>;           // Google marker type: {} — signalled by KEY PRESENCE
  relativeDiscount?: string | number;           // fraction, 0 < x < 1 exclusive, scale 8. 0.2 = 20% off
  absoluteDiscount?: Money;                     // currency must equal the region's base currency;
                                                //   must not exceed the region's base price; 0 is legal
}

interface Money { currencyCode: string; units: string | number; nanos: number; }  // /^[A-Z]{3}$/, units >= 0, nanos 0..999999999
interface OfferTag { tag: string; }                                              // /^[a-z0-9-]{1,20}$/ — leading hyphen allowed
```

### 3.3 Read: an offer in the catalogue and Console detail

```ts
interface OfferRead {
  offer_id: string;
  state: OfferState;                            // output only
  offer_token: string;                          // `otk_` + 32 base64url chars = 36 total
  offer_tags: string[];
  price: MoneyEnvelope;                         // the PAYABLE amount
  discount: FlatDiscount | null;                // lossy projection for unmigrated clients
  time_window: { startMillis: number; endMillis: number } | null;
  discounted_offer: { start_time: string; end_time: string; redemption_limit: number } | null;
  regional_pricing_and_availability_configs: RegionRead[];   // sorted by region_code
}

interface RegionRead {
  region_code: string;
  availability: OfferAvailability;
  pricing_variant: OfferPricingVariant;
  relative_discount: string | null;
  absolute_discount: MoneyEnvelope | null;
  base_price: MoneyEnvelope | null;             // null when the region has no base price — not an error
  resolved_price: MoneyEnvelope | null;
}

interface MoneyEnvelope { currency: string; value: string; label: string; symbol: string; micros: number; }
```

**Effective price** (document the formula, not the implementation):

```
discount = round_half_up(base × fraction)         // relativeDiscount
resolved = max(0, base − discount)                 // the discount is clamped, so base − discount = resolved exactly
```

The Console **offers list / batchGet** shape is deliberately leaner — `region_code`, `availability`, `pricing_variant` only, and **no `offer_token`**.

### 3.4 Lifecycle request bodies

```ts
// offers:batchUpdateStates                     1..100 items
{ requests: { offerId: string; state: 'ACTIVE' | 'INACTIVE' }[] }

// offers:batchDelete · offers:batchGet         1..100 items; ids required when the path segment is `-`
{ requests: { offerId: string; productId?: string; purchaseOptionId?: string }[] }

// purchaseOptions:batchUpdateStates            1..100 items
// per-product variant:   productId in the body is IGNORED (the path wins)
// cross-product variant: productId is REQUIRED per item
{ requests: { purchaseOptionId: string; state: PurchaseOptionState; productId?: string }[] }

// purchaseOptions:batchDelete                  1..100; a body productId is NOT accepted
{ requests: { purchaseOptionId: string }[] }

// oneTimeProducts:batchDelete                  1..100 — note: NOT Google-shaped, snake_case
{ product_ids: string[] }
```

`:activate` and `:deactivate` take **no body** — all ids are in the path — and return **204**.

### 3.5 Error envelopes

```ts
// v3 surface only (/androidpublisher/v3/...)
interface GoogleError { error: { code: number; message: string;
  errors: { message: string; domain: 'global'; reason: string; location?: string }[];
  status: 'INVALID_ARGUMENT' | string } }

// every other surface, including all Console endpoints
interface AptSdkError { code: string; path: string; text: string; data: unknown | null }
```

Conflict codes to document verbatim, as callers match on them: `INVALID_STATE_TRANSITION`, `LAST_OFFER_OF_ACTIVE_OPTION`, `PURCHASE_OPTION_NOT_DELETABLE`, `AMBIGUOUS_LEGACY_OPTION`.

---

## 4. Testing Requirements

There is no test runner in this repository and adding a framework is out of scope. Verification is therefore two checkable scripts plus two human passes — all four are gates, not suggestions.

| Check | Type | Gate |
|---|---|---|
| **Claim ledger complete** — every published cap, enum set, status code and error code has a row with a source citation and no `pending` status | manual, ledger-driven | NFR-01, TR-18 |
| **Link check** — extract every relative Markdown link and assert the target file exists; run from the repo root | script (`grep -oE` + `test -f`); ~10 lines of shell, kept in the planning directory, **not** shipped in `docs/` | NFR-04 |
| **Leakage check** — `grep -rE '\.php|ADR-0|V8_OTP_|origin/staging|database/' docs/ README.md` must return nothing | script | NFR-03 |
| **Index parity** — generated file list diffed against the two hand-maintained index lists | script | NFR-05 |
| **Structural pass** — every new page has the required blocks in order, and a surface preamble | manual checklist | NFR-08, TR-12 |
| **Spot re-verification** — pick 10 published numbers at random, re-derive each from source independently of the ledger | manual | catches ledger-authoring errors, which the ledger cannot catch itself |

The spot re-verification exists because the ledger is self-reported: a wrong number copied into both page and ledger passes every other check.

---

## 5. Migration Plan

No data, no schema, no code — but there **is** a URL surface, and it is the thing that can break.

- Portal URLs mirror file paths. **Moving or renaming an existing page breaks a live URL**, the root endpoint table, and any external bookmark — including whatever PAY-1888 links.
- **Therefore: additive only.** New files and directories; existing files edited in place. Enforced by TR-16 and checkable with `git diff --stat` showing zero renames.
- Nothing needs backfilling, and no redirect mechanism exists in the portal — which is precisely why "additive only" is a hard constraint rather than a preference.
- Deployment is the portal's existing step that populates its git-ignored docs directory. No portal change, no coordination window, no downtime.

**Sequencing constraint:** if PAY-1888 will link to specific page paths, the page names in ADR-001 must be agreed with that ticket **before** either lands, because renaming afterwards is the one thing this plan forbids.

---

## 6. Feature Flag Strategy

This repository has no flag mechanism, and the deliverable cannot be dark-launched — a merged page is a published page at the next deploy. The relevant flags belong to the *documented system*, and the strategy is how the pages behave with respect to them (ADR-003):

- The Console surface is gated by two flags defaulting to `false`; their production values are unknown and were asked on the ticket.
- Pages therefore carry an **availability marker** — "generally available" or "limited availability" with a 404 explanation — so each page is correct under either state.
- Default: mark the eleven Console endpoint pages **limited availability**.
- **No internal flag name, environment variable or deploy state is published** (ADR-005).
- **Follow-up, recorded on the ticket:** when the flags are confirmed enabled, flip the markers. One line per page.

Staged publication is available if preferred and needs no mechanism: land the v3-surface edits (`batchUpdate.md`, the resource page, the type pages) in one commit, and the Console pages in a second. This is the recommended shape — see the phasing note in §7.

---

## 7. Rollback Plan

Specific, because it is genuinely simple — and the simplicity is a design property worth stating.

**Blast radius:** documentation only. No endpoint, payload, schema or client behaviour changes. The worst realistic outcome is a published inaccuracy — the same class of problem this ticket fixes, which is why the ledger and the spot check exist.

| Scenario | Action | Recovery |
|---|---|---|
| A wrong number or claim is found post-merge | Fix forward: correct the page **and** its ledger row in one commit | next deploy |
| A page is materially wrong or misleading | `git revert <commit>` — additive-only means a revert cleanly removes new files and restores modified pages, with no orphaned links, because index entries are in the same commits | next deploy |
| Console endpoints turn out to be disabled and the marker is judged insufficient | Move the affected pages into the existing `<details>` "not implemented" block, or revert the second commit if phased per §6 | next deploy |
| A relative link breaks the portal's navigation | Fix the link; the portal falls back to `index.md` in the same folder for an unresolved path, so a broken link degrades to a wrong page rather than an error | next deploy |
| The whole approach is rejected in review | `git revert` both commits; the repository returns to `d1b25c8` behaviour with no residue | next deploy |

**Preconditions that make rollback safe** — all already required elsewhere in this spec: no existing file is moved (TR-16), index updates ship in the same commit as the pages they list (TR-15), and the work is split into two commits by surface (§6). Without the first, a revert would leave dead URLs; without the second, a revert would leave index entries pointing at deleted files.

**Not recoverable by revert:** nothing. There is no external side effect — no cache to purge, no client to notify, no migration to reverse.

---

## Artifacts produced in this phase

- `03_ARCHITECTURE.md`
- `03_ADR-001-page-structure-by-surface.md`
- `03_ADR-002-provenance-and-enforcement-markers.md`
- `03_ADR-003-availability-status-over-omit-or-publish.md`
- `03_ADR-004-scope-not-implemented-list-per-surface.md`
- `03_ADR-005-no-internal-identifiers-in-published-pages.md`
- `03_ADR-006-document-offer-token-as-defined-contract.md`
- `03_PROJECT_SPEC.md` (this file)
