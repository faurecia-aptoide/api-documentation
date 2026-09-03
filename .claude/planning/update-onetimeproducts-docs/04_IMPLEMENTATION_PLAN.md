# Implementation Plan: update-onetimeproducts-docs

**Issue:** PAY-1889 · **Phase:** 4 (Planning) · **Date:** 2026-09-03

## Overview

- **Total Phases:** 8
- **Estimated Effort:** M — no code, one repository, an established page pattern; the cost is per-claim source verification, which is slow and cannot be parallelised away
- **Dependencies:**
  - **Hard:** a read-only detached worktree of `web-product-service-laravel` @ `origin/staging` `c4dd77a`, created under the local session scratchpad (`git worktree add --detach <local-path> c4dd77a`; path is machine-specific, so not recorded here).
    Every ledger row cites that commit. If the worktree is removed, re-create it at the **same commit** — re-verifying against a newer tip mid-ticket would mix two contracts in one document.
  - **Soft, non-blocking:** deployed values of the two Console flags (affects only the ADR-003 marker wording), whether the broker PR merged (affects only one ADR-006 status line), and the two cited audit artefacts (affects only ADR-004's confidence). Asked on the ticket; the plan proceeds without them.
  - **Coordination:** if PAY-1888 (D1) will link to specific page paths, agree the Phase 4–7 filenames **before** Phase 4 lands. Additive-only forbids renaming afterwards.
- **Feature Flag:** none in this repository — a merged page publishes at the next deploy. Flags belong to the documented system and are handled by the ADR-003 availability marker.

### Commit and revert boundaries

One commit per phase. Two boundaries matter for a coherent revert:

| Revert | Restores |
|---|---|
| Phase 8 alone | pre-verification state, pages intact |
| Phases 4–7 together | v3-surface-only documentation — coherent, because no Phase 1–3 page links into the Console pages except the ADR-004 list (see Phase 3, Task 3.5) |
| Phases 1–8 | `d1b25c8` behaviour with no residue |

Index updates ship **in the same commit as the pages they list** (TR-15), so no revert leaves an index entry pointing at a deleted file.

### Ordering rationale

Interface-first: the marker vocabulary and check scripts come first (Phase 1), then leaf type pages (Phase 2), then the pages that reference them (Phases 3–7). Verification closes (Phase 8). Phase 3 is deliberately before the Console phases so the highest-value, lowest-risk work — the caps the ticket leads with — lands first and can ship alone if the Console decision reverses.

---

## Phase 1: Conventions and verification harness

### Objective
Define the reusable page furniture from ADR-002/003 and build the three mechanical checks, so every later phase is written against a fixed convention and checkable the moment it is written. No published page changes in this phase.

### Tasks
- [ ] 1.1: Create the claim ledger skeleton with the six-column table and a `pending`/`verified`/`rejected` status vocabulary — `.claude/planning/update-onetimeproducts-docs/04_CLAIM_LEDGER.md`
- [ ] 1.2: Write the canonical snippet definitions — surface preamble (v3 and Console variants), availability marker (both values), provenance marker vocabulary, enforcement-table header — `.claude/planning/update-onetimeproducts-docs/04_PAGE_CONVENTIONS.md`
- [ ] 1.3: Write the link-check script: extract every relative Markdown link under `docs/` and the root `README.md`, assert each target exists — `.claude/planning/update-onetimeproducts-docs/scripts/check-links.sh`
- [ ] 1.4: Write the leakage-check script: `grep -rE '\.php|ADR-0|V8_OTP_|origin/staging|[0-9a-f]{7,40}|database/'` over `docs/` and `README.md`, exit non-zero on any hit — `scripts/check-leakage.sh`
- [ ] 1.5: Write the index-parity script: generate the file list from the tree, diff against the section `README.md` lists and the root endpoint table — `scripts/check-index-parity.sh`
- [ ] 1.6: Record the three ticket claims the code contradicts as ledger rows with status `rejected` and their evidence, so the rejections are auditable rather than merely discussed — `04_CLAIM_LEDGER.md`

### Tests
- [ ] All three scripts run clean against the **current, unmodified** repository — this is the baseline; a script that fails now is measuring itself, not the work
- [ ] Leakage script proves it can fail: temporarily add a line containing `BatchUpdateItem.php` to a scratch file, confirm non-zero exit, remove it
- [ ] Link script proves it can fail: point it at a deliberately broken link in a scratch file, confirm non-zero exit
- [ ] Ledger opens correctly in a Markdown renderer (table syntax valid)

### Acceptance Criteria
- Three scripts exist, are executable, pass on the untouched repository, and each has been shown to fail on a planted defect
- Convention document defines every block later phases will paste, with no open choices left
- Ledger contains the three `rejected` rows
- **Zero changes under `docs/` or to `README.md`**

### Rollback
`git revert` — nothing published changed. Scripts and planning files live outside `docs/` and are never deployed.

---

## Phase 2: Type pages (leaf contracts)

### Objective
Publish the eight new `types/` pages that later pages reference, so no page in Phases 3–7 links to a type that does not exist yet.

### Tasks
- [ ] 2.1: `types/offer-state.md` — three values, transition table, `STATE_UNSPECIFIED` must-not-send, `CANCELLED` not modelled
- [ ] 2.2: `types/purchase-option-state.md` — four values, transition table, `DRAFT`-only deletability marked **Appning, stricter**
- [ ] 2.3: `types/offer-availability.md` and `types/offer-pricing-variant.md` — three values each; the availability page states that nothing filters on it and hiding is a client obligation (TR-14)
- [ ] 2.4: `types/relative-discount.md` and `types/absolute-discount.md` — fraction with exclusive bounds (**not** a percentage); currency-must-match-region and must-not-exceed-base rules
- [ ] 2.5: `types/resolved-price.md` — the money envelope, the `base − discount = resolved` formula, half-up rounding, and `null` when a region has no base price
- [ ] 2.6: `types/offer-token.md` — format and derivation only; the integration flow is Phase 7 (ADR-006 register 1)
- [ ] 2.7: Add all eight pages to the section index — `docs/.../monetization.onetimeproducts/README.md` (structure + covered sub-links)
- [ ] 2.8: Add a ledger row per published enum value, bound and formula

### Tests
- [ ] Link check passes (new pages are not yet linked *from* elsewhere, but their own `Local references` must resolve)
- [ ] Leakage check passes
- [ ] Index parity passes — the eight pages appear in both `README.md` lists
- [ ] Structural pass: each page has `# Enum:`/`# Schema:` heading, `Adapted from:`, body, `## Local references`
- [ ] Every enum set is **complete and closed** — cross-check each against the source enum file, counting cases (3/4/3/3)

### Acceptance Criteria
- Eight pages exist and match the existing `types/` page shape
- Every enum value, bound and formula has a `verified` ledger row citing `file:line` @ `c4dd77a`
- No page exceeds 40 KB / 500 lines (NFR-02)
- All four scripts/passes green

### Rollback
`git revert` — removes eight new files and the index entries added in the same commit. Nothing else references them yet, so the tree stays coherent.

---

## Phase 3: v3 surface — the caps and the write contract

### Objective
Deliver the ticket's headline items on the surface this repository already documents: every enforced cap with its provenance, the unknown-key rejection, the `updateMask` root lists, the `offers[]` write shape and the per-region pricing union. Highest value, lowest risk; shippable alone.

### Tasks
- [ ] 3.1: Add the enforcement table to `docs/.../batchUpdate.md` — all eleven caps with value, scope, provenance and *when* enforced (TR-01, TR-02); include the combined-ceiling non-regression behaviour (TR-03)
- [ ] 3.2: Document unknown-key rejection in `batchUpdate.md` — where it applies, at most 10 keys reported plus the "more not listed" line, and that it triggers on key **presence**, not value
- [ ] 3.3: Document the `updateMask` contract in `batchUpdate.md` — the three root lists (allowed / not-yet-supported / immutable), snake_case→camelCase normalisation, optional `oneTimeProduct.` prefix stripping, and the three distinct rejection messages
- [ ] 3.4: Add the error catalogue and the two-bucket behaviour to `batchUpdate.md` — including that **`missing` wins and discards the invalid list**, so a caller may see a different error set on retry
- [ ] 3.5: Extend `docs/.../monetization.onetimeproducts.md` — `purchaseOptions[].offers[]`, the per-region pricing union (TR-04), provenance markers on every field, `type` documented **as rejected** (TR-08), and the ADR-004 not-implemented list rewrite (TR-11)
- [ ] 3.6: Document replace-not-merge semantics on both pages (TR-13) and the client obligations that belong to the write contract — lossy `offers[].discount` projection (TR-14)
- [ ] 3.7: Add the v3 surface preamble to both pages, and the sandbox base URL plus issuer-aware catalogue rate limits (TR-12, TR-17)
- [ ] 3.8: Ledger rows for every claim added in this phase

### Tests
- [ ] All three scripts pass
- [ ] Structural pass on both modified pages
- [ ] **Diff review against TR-16:** `git diff --stat` shows zero renames, and the *only* previously-certified text altered is the not-implemented list (Task 3.5)
- [ ] Spot re-verification: independently re-derive 5 of the eleven caps from source without consulting the ledger
- [ ] Confirm no page states an Appning cap as Google's — grep the enforcement table for a provenance value on every row

### Acceptance Criteria
- All eleven caps published with matching numbers and correct provenance
- `type` documented as rejected; the ticket's asymmetry claim is **not** published
- Not-implemented list scoped per surface and cross-linked (targets exist from Phase 2 or are Phase 4–7 pages — see Rollback note)
- Every claim has a `verified` ledger row
- All tests green

### Rollback
`git revert` restores the two pages to their `d1b25c8` content. **Note:** Task 3.5's cross-links point at Phase 4–7 pages. If Phases 4–7 are reverted while Phase 3 stands, those links break — the link-check script will catch it, and the fix is to collapse the list back to the plain "not implemented" form. Recorded because it is the one cross-phase coupling in this plan.

---

## Phase 4: Offer resource and reads

### Objective
Introduce the Console surface with its own directory, and publish the offer resource plus its two read endpoints.

### Tasks
- [ ] 4.1: Create `docs/.../offers/README.md` — offer surface index with the Console preamble
- [ ] 4.2: Create `offers/offers.md` — the Offer resource: full read shape, `state` as output-only, the transition table (linking `types/offer-state.md`), and the two sellability gates with inclusive-start/exclusive-end schedule semantics
- [ ] 4.3: Create `offers/list.md` — `pageSize` default 50 **coerced** to 1–1000 (not rejected), `pageToken`/`nextPageToken` always present, `-` wildcard rules including the 400 on specific-option-under-wildcard-product, and that every state including DRAFT is returned
- [ ] 4.4: Create `offers/batchGet.md` — 1–100 targets, response order is a contract, and **unresolvable offers are absent, not 404**
- [ ] 4.5: Add the ADR-003 availability marker to all three endpoint-bearing pages
- [ ] 4.6: Note the leaner Console offer shape — `region_code`, `availability`, `pricing_variant` only, and **no `offer_token`** — to prevent a reader assuming the buyer shape
- [ ] 4.7: Update both indexes — section `README.md` and the root `README.md` endpoint table
- [ ] 4.8: Ledger rows for this phase

### Tests
- [ ] All three scripts pass, including index parity for the new directory
- [ ] Structural pass, plus: every page carries the **Console** preamble and the availability marker
- [ ] Verify the error envelope shown is `{code,path,text,data}`, **not** the Google envelope — the single most likely conflation error
- [ ] Confirm the offers-list page does not show `offer_token` in its response example

### Acceptance Criteria
- Four pages exist; offer resource, states and transitions fully documented
- Console preamble and availability marker on every endpoint page
- Correct error envelope throughout
- Ledger complete for the phase; all tests green

### Rollback
`git revert` — removes the directory and its index entries together. Phase 3's ADR-004 cross-links to `offers/` would break; see Phase 3 Rollback.

---

## Phase 5: Offer lifecycle writes

### Objective
Publish the four state-changing offer endpoints — the ticket's `:activate`, `:deactivate`, `:batchUpdateStates`, `:batchDelete`.

### Tasks
- [ ] 5.1: Create `offers/activate.md` and `offers/deactivate.md` — **no request body**, all ids in the path, **204** empty response, fixed target states, and that a same-state call is a legal no-op that writes nothing
- [ ] 5.2: Create `offers/batchUpdateStates.md` — `{requests:[{offerId,state}]}` 1–100, `ACTIVE`/`INACTIVE` only, with the three distinct 400 cases (`STATE_UNSPECIFIED`, `CANCELLED`, unknown state)
- [ ] 5.3: Create `offers/batchDelete.md` — target shape, wildcard-id requirements, no state restriction, and the **409 `LAST_OFFER_OF_ACTIVE_OPTION`** guard with its reason
- [ ] 5.4: Document the 409 conflict codes verbatim on each page, since callers match on the strings
- [ ] 5.5: Document idempotency behaviour — write endpoints carry idempotency handling; reads deliberately do not
- [ ] 5.6: Add availability markers and Console preambles to all four pages
- [ ] 5.7: Update both indexes
- [ ] 5.8: Ledger rows for this phase

### Tests
- [ ] All three scripts pass
- [ ] Structural pass; preamble and availability marker on all four pages
- [ ] Cross-check the transition table on each page against `types/offer-state.md` — a contradiction between two of our own pages is the failure mode here
- [ ] Verify every documented status code (204/400/404/409) against the controller and lifecycle service
- [ ] Confirm no page implies `:cancel` exists

### Acceptance Criteria
- Four pages exist, each with body, success status and complete error cases
- Conflict code strings match source exactly
- No contradiction between any two pages on the transition rules
- Ledger complete; all tests green

### Rollback
`git revert` — removes four files and their index entries. `offers/README.md` from Phase 4 would list missing pages, so **revert Phase 5 before or with Phase 4**, never Phase 4 alone. Stated because it is the one ordering constraint among the Console phases.

---

## Phase 6: Purchase-option state transitions

### Objective
Publish the purchase-option lifecycle endpoints, including the cross-product variant that is an Appning extension rather than a Google method.

### Tasks
- [ ] 6.1: Create `docs/.../purchase-options/README.md` — index with the Console preamble
- [ ] 6.2: Create `purchase-options/batchUpdateStates.md` covering **both** variants on one page: per-product (body `productId` ignored, path wins) and cross-product (body `productId` **required**), the latter marked **Appning** (TR-07)
- [ ] 6.3: Document the four-state transition table and the two observable side effects: **409 `AMBIGUOUS_LEGACY_OPTION`** on colliding legacy-compatible active options, and the legacy price re-projection
- [ ] 6.4: Create `purchase-options/batchDelete.md` — per-product only, no cross-product variant, body `productId` not accepted at all, **409 `PURCHASE_OPTION_NOT_DELETABLE`** unless `DRAFT` (marked **Appning, stricter**), and that unknown ids are skipped while the call still succeeds
- [ ] 6.5: State that multiple purchase options per product are supported, correcting the single-`default` assumption a reader may hold from the older documentation
- [ ] 6.6: Add availability markers and preambles
- [ ] 6.7: Update both indexes
- [ ] 6.8: Ledger rows for this phase

### Tests
- [ ] All three scripts pass
- [ ] Structural pass; preamble and availability marker present
- [ ] Verify the two variants' `productId` handling against the request class — inverted rules here would be a silent, expensive integrator error
- [ ] Cross-check the state table against `types/purchase-option-state.md`
- [ ] Confirm `DRAFT`-only deletability is marked **Appning, stricter** and not presented as Google parity

### Acceptance Criteria
- Three pages exist; both `:batchUpdateStates` variants documented with their differing `productId` rules
- Both Appning-specific rules correctly marked
- Ledger complete; all tests green

### Rollback
`git revert` — self-contained directory plus its index entries. No other phase links into it except the Phase 3 not-implemented list.

---

## Phase 7: `offer_token` integration contract

### Objective
Publish ADR-006 register 2 — how a client uses the token — with the exact tense, plus the remaining cross-cutting client obligations.

### Tasks
- [ ] 7.1: Extend `types/offer-token.md` (or add `offers/offer-token-flow.md` if the type page would exceed NFR-02) with the resolution contract: which responses carry the token, that it names an offer rather than authorising a price, and the one status line stating no broker forwards it yet
- [ ] 7.2: Publish the client rules as rules — read `price.value` with `price.currency` and **never `price.micros`** (scale differs; misreading mis-prices by 100×); parse as a decimal without assuming two decimal places
- [ ] 7.3: Publish the remaining rules — no token-lookup endpoint exists or is planned; do not cache a resolved token or catalogue response across requests; fail closed on an unresolvable token; surface one message for "ended" and "invalid", which are indistinguishable by construction
- [ ] 7.4: Document `redemptionLimit` end to end per TR-10 — Google's 1–50 range on write, counted per buyer at purchase time with a 403 at the cap, and explicitly a **merchandising control, not a security control**
- [ ] 7.5: Document the EEA display obligation (TR-14) — discounted price only, no strikethrough, in the named regions; unenforced by the service and selected by the option's `withdrawalRightType`
- [ ] 7.6: Verify no internal state leaked — no flag names, branch or PR numbers, environment variables, secret-configuration detail, or latency figures (ADR-005, ADR-006, NFR-11)
- [ ] 7.7: Update both indexes if a new page was added
- [ ] 7.8: Ledger rows for this phase

### Tests
- [ ] All three scripts pass; leakage check is the primary gate for this phase
- [ ] Tense review: every sentence in register 1 is present-tense fact; every sentence in register 2 is contract-plus-status. No sentence claims the flow is in use today
- [ ] Grep for `ms`, `p99`, `per second` — must return nothing (NFR-11)
- [ ] Confirm `redemptionLimit` appears **nowhere** in an "accepted, not enforced" list (TR-09)

### Acceptance Criteria
- The token's format, derivation, non-reversibility, absence of expiry and response placement are published as present fact
- All six client rules published
- `redemptionLimit` described as enforced at purchase time and not as a security control
- Zero internal identifiers or unmeasured performance claims
- Ledger complete; all tests green

### Rollback
`git revert`. If Task 7.1 extended the Phase 2 type page rather than adding a file, the revert restores that page to its Phase 2 content — no index change needed, which is why extending is preferred where NFR-02 allows.

---

## Phase 8: Verification and closure

### Objective
Prove the acceptance criteria mechanically rather than by assertion, then close the loop on the ticket.

### Tasks
- [ ] 8.1: Run all three scripts across the whole repository; fix any failure and re-run to green
- [ ] 8.2: Ledger completeness audit — every published cap, enum set, status code and error code has a row; **zero** rows remain `pending` (NFR-01, TR-18)
- [ ] 8.3: Spot re-verification of **10** randomly chosen published numbers, re-derived from source *without* consulting the ledger — this is the only check that can catch a wrong number copied identically into both page and ledger
- [ ] 8.4: Measure NFR-02 across all pages (`wc -c`, `wc -l`); split any page over budget
- [ ] 8.5: Full-tree review against TR-15/TR-16 — indexes match the tree exactly; `git diff --stat` shows zero renames across all commits
- [ ] 8.6: Terminology and accessibility pass (NFR-09, NFR-10) — one term per concept; every table has a header row; no meaning carried by symbol alone
- [ ] 8.7: Read every new page once as an integrator who has never seen the API, listing anything unanswerable; fix or record as follow-up
- [ ] 8.8: Update the ticket — what shipped, the three rejected claims with evidence, the ADR-003/004/006 decisions, and the follow-ups (flag-marker flip, `offer_token` status line, source-repo doc drift)

### Tests
- [ ] All three scripts green on the final tree
- [ ] Ledger audit: 100% coverage, zero `pending`
- [ ] 10/10 spot re-verifications match
- [ ] Every page within NFR-02 budget
- [ ] Zero renames in the cumulative diff

### Acceptance Criteria
- Every success criterion in `01_DISCOVERY.md` maps to a passing check or a `verified` ledger row
- The three rejected ticket claims are recorded with evidence, not silently omitted
- Ticket carries the closing comment
- No `pending` claim published anywhere

### Rollback
Fix forward — this phase adds no published content beyond corrections. If a systemic problem surfaces here, revert by the boundaries in the Overview (Phases 4–7 for the Console surface; all phases for a full reset).

---

## Test Strategy

This repository has no test runner, and adding a framework is out of scope (`03_PROJECT_SPEC.md` §4). The strategy substitutes mechanical checks plus two human passes for automated tests, and each phase runs them rather than deferring to the end.

### Unit tests → per-claim source verification

- **Coverage target: 100%** of published numeric caps, enum vocabularies, status codes and error-code strings (NFR-01). A documentation claim is the unit here; its "assertion" is a `file:line` citation at `c4dd77a`.
- **Key areas:** the eleven caps; four enum sets and their exact case counts; the union exactly-one rules; status codes per endpoint; the four 409 conflict strings; provenance of every Appning-specific rule.
- **Mocking strategy: none, and deliberately so.** Every claim is verified against the real source at a pinned commit. The nearest thing to a mock — reading an ADR, a docblock or an OpenAPI schema instead of the parser — is precisely the failure that produced this ticket, and is forbidden by ADR-005.

### Integration tests → cross-page and cross-index consistency

- **Link check** — every relative link resolves (NFR-04). Runs every phase.
- **Index parity** — file tree ≡ section index ≡ root endpoint table (NFR-05). Runs every phase; catches the drift that additive-only growth invites.
- **Leakage check** — no internal identifiers in published pages (NFR-03). Runs every phase; primary gate in Phase 7.
- **Cross-page contradiction checks** — transition tables on endpoint pages against their type pages (Phases 5, 6). Two of our own pages disagreeing is a distinct failure from either page disagreeing with the code, and only this check finds it.

### E2E tests → portal rendering

The portal cannot be exercised from this repository, so E2E is **constrained by construction rather than tested**: pages use only CommonMark plus the `<details>`/`<summary>` and `<a href>` constructs already proven in the existing pages (NFR-07). Any new HTML construct would be an untested change to a rendering path we cannot observe, so none is introduced. If a portal preview environment is available, one page from each new directory should be spot-rendered; recorded as optional because its availability is unknown.

### Performance tests

- **Baseline to capture:** current 13 files / 526 total lines, and per-page byte size.
- **Budget:** ≤ 40 KB and ≤ 500 lines per page (NFR-02); measured in Phase 8, Task 8.4.
- **Scenario worth noting, not load-testing:** the portal walks the entire file tree on every page view, so total file count — not page size — drives render cost. ~18 new files roughly doubles that walk from a trivial base. Recorded so the trigger for generating indexes and caching the tree is known (`03_ARCHITECTURE.md` §8); no action needed at this scale.

### What this strategy cannot catch

Stated plainly, because a test plan that oversells itself is its own risk:

- A number wrong in **both** page and ledger — only the Phase 8 spot re-verification samples for this, and it samples 10.
- A claim that was true at `c4dd77a` and changes afterwards. Nothing here detects drift; the ledger only makes re-verification cheap. A drift guard belongs in the source repo, where the console OpenAPI spec already has one — a recommended follow-up, not this ticket.
- Ambiguity or omission. Task 8.7's cold read is the only defence, and it is a judgement, not a check.
