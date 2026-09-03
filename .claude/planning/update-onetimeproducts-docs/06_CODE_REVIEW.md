# Code Review: update-onetimeproducts-docs

**Issue:** PAY-1889 · **Phase:** 6 (Review) · **Date:** 2026-09-03
**Reviewed:** `d1b25c8..0c8793f` (7 commits, 24 files, 20 new pages + 4 modified, +1462/-11)
**Method:** every changed page read in full against the diff; every finding below re-derived independently from `web-product-service-laravel` @ `origin/staging` `c4dd77a` (the same pinned commit implementation used), without consulting the claim ledger first. Ledger rows were checked against source only *after* an independent reading, so a wrong ledger row could not anchor a wrong review conclusion.

---

## 1. Automated Checks

This repository has no linter, type checker, test runner or build step (confirmed in `01_DISCOVERY.md`; no `package.json`, no CI config). The equivalent gates for a documentation deliverable are the three scripts built in Phase 1. Re-run fresh for this review, against the full repository, not just the changed files:

| Check | Command | Result |
|---|---|---|
| Relative links resolve | `sh scripts/check-links.sh` | **PASS** |
| No internal identifiers / hashes / unmeasured perf claims | `sh scripts/check-leakage.sh` | **PASS** |
| File tree matches both hand-maintained indexes | `sh scripts/check-index-parity.sh` | **PASS** |
| Ticket-number leakage (`PAY-\d+`) | ad hoc grep, this review | **PASS** — none found |
| `TODO`/`FIXME` left in published pages | ad hoc grep, this review | **PASS** — none found |
| Ledger row count / duplicate IDs | ad hoc grep, this review | **PASS** — 135 rows, 0 duplicates |
| Worktree still pinned to `c4dd77a` | `git rev-parse --short HEAD` in the worktree | **PASS** |

All automated gates pass. See §3 for where these checks have blind spots that this manual pass found.

---

## 2. Manual Code Review

### 🔴 Critical

**1. The EEA discount-display rule is stated less precisely than the source, in a compliance-sensitive way.**
File: `docs/appning/android-publisher/monetization.onetimeproducts.md`, section "Displaying a discounted price in the EEA" (new).

Published text:
> In the European Economic Area, a buyer must be shown **only the discounted price**, with **no strikethrough** of the original.

Source (`docs/api/v8-one-time-products.openapi.yaml`, catalog operation description; corroborated in `docs/architecture/one-time-products.md`):
> In BE, HR, CZ, DK, EE, FR, GR, LV, PL, SE (digital content) and BE, HR, CZ, DK, FR, GR, HU, LV, NL, PL, SE (digital services), the buyer must see ONLY the discounted price, with **NO mention of the offer** — no strikethrough, no "was X now Y".

Two compounding inaccuracies, both checkable and both already available in the very source this ticket was implemented against:

- **Scope.** The rule applies to two specific, *non-identical* lists of EEA member states (10 for digital content, 11 for digital services — services adds `HU`/`NL`, content adds `EE`), not to "the European Economic Area" as a whole. The published page never states which countries are covered, and the page it links to (`types/withdrawal-right-type.md`, pre-existing and unmodified) doesn't list them either — so a reader who wants to implement this correctly has no way to find the country list from this documentation set at all.
- **Content of the obligation.** The source rule is "no mention of the offer" — strikethrough is given only as one example, alongside "no 'was X now Y'" framing. The published page narrows this to "no strikethrough", which would read as compliant a UI that shows a "20% OFF" or "Limited offer" badge next to the price with no strikethrough — a real and common pattern that the actual rule prohibits.

**Why Critical:** this is legal/compliance guidance, not an API-shape detail. An integrator who implements exactly what this page says can ship a UI that violates the documented Google policy while believing they followed Appning's documentation. The source text was read and cited correctly elsewhere in this same PR (see the source excerpt above matches almost verbatim what research captured in `02_CODE_RESEARCH.md` §4.5) — this is a compression introduced during page-writing, not a research gap.

**Required fix:** state the rule as "no mention of the offer — no strikethrough, no 'was X now Y' framing", and either enumerate both country lists inline or add them to `types/withdrawal-right-type.md` (which currently has no country list either, on either the old or new content) and link to it.

---

### 🟡 Important

**2. A forward reference was never restored to a real link.**
File: `docs/appning/android-publisher/monetization.onetimeproducts/types/offer-token.md`, "## Using it":

```
See `offer-token-flow` for what a client does with the token, including the rules for reading a price correctly.
```

This is plain code-formatted text, not a Markdown link — `check-links.sh` only scans `](...)` syntax, so it never saw this. It is a leftover from the Phase 2→Phase 7 forward-link deferral pattern used throughout this implementation (type pages written before their targets existed link nothing yet, then get the link restored once the target page exists). Every other deferred reference in this PR was correctly restored to a real link when its target landed in a later phase (verified: `grep` for the other deferral phrasings used in Phases 2–3 found zero remaining instances). This one specific instance — on the page whose entire "Using it" section exists to route the reader to the integration contract — was missed.

**Required fix:** `See [`offer-token-flow.md`](../offers/offer-token-flow.md) for …`

**3. The redemption-count exclusion rule omits one of its two independent conditions, on both the page and its ledger row.**
Files: `docs/appning/.../offers/offer-token-flow.md` and `04_CLAIM_LEDGER.md` row `P7-07`.

Published: *"A purchase stops counting towards the limit if it is refunded, charged back or cancelled."*

Source (`app/Support/Offers/RedemptionCountRule.php:96-109`, re-verified independently for this review): a purchase does **not** count when **either** (a) the purchase's own status is `VOIDED`, **or** (b) its latest order's status is `REFUNDED`/`CHARGEDBACK`/`CANCELED`. These are two separate fields on two separate objects (`Purchase.status` vs. the latest `Order.status`), not three variants of one condition. The published sentence covers only (b) and drops `VOIDED` entirely.

That the omission is identical on the page *and* in the ledger row that is supposed to be the independent citation for it indicates the gap originated at claim-capture time, not in phrasing during page-writing — and neither the Phase 7 authoring pass nor the Phase 8 audit caught it, because the audit's spot-check sample didn't happen to include this row.

**Required fix:** add "or the purchase itself was voided" (or equivalent), on both the page and the ledger row.

**4. Sandbox host is documented on 3 of 9 new/modified endpoint pages, inconsistently.**
Present on: `batchUpdate.md`, `offers/list.md`, `purchase-options/batchUpdateStates.md`. Absent from: `offers/batchGet.md`, `offers/activate.md`, `offers/deactivate.md`, `offers/batchUpdateStates.md`, `offers/batchDelete.md`, `purchase-options/batchDelete.md`.

`03_PROJECT_SPEC.md` TR-17 lists the sandbox base URL as a requirement, and it's satisfied on the first page written (`batchUpdate.md`, Phase 3) but the pattern wasn't propagated to most of the pages written in Phases 4–6. This isn't a factual error — an integrator can infer the sandbox host from the one pattern that's consistently shown (`product.` → `product-sandbox.`) — but it is a real, checkable inconsistency against NFR-09 (terminology/structural consistency) that a `grep` finds immediately, which is exactly the kind of gap a per-page checklist should have caught.

**Required fix:** add the `Sandbox:` line to the six pages listed above, or explicitly decide (and note in `04_PAGE_CONVENTIONS.md`) that it belongs only on the first page of each surface's method list — but the current state is neither.

**5. The closing summary overstates what shipped for the four Console-level product methods.**
The Jira closing comment and `03_ADR-004` both describe the "not implemented" list rewrite as splitting into "available on the seller surface" (**cross-linked**) and "not implemented anywhere". For the offer- and purchase-option-level methods this is true — every one of them got a full page. For the four **product**-level Console methods now listed as available (`list`, `get`, `delete`, `batchDelete` under `/sellers/{uid}/inapp/oneTimeProducts`) it is not: `monetization.onetimeproducts.md` names them in four plain bullets with no link, because no pages for them exist. That's a defensible scope call — these four were never in the ticket's ask, and building them out was correctly left off the implementation plan — but "cross-linked" is not an accurate description of a plain-text bullet with nowhere to click, and a reviewer reading only the ticket comment would reasonably expect otherwise.

**Required fix:** either (a) correct the closing description to say these four are named but not yet individually documented, and open a follow-up, or (b) add minimal pages for them now, matching the existing method-page shape, since the route paths and basic shapes are already known from `routes/api.php` and would cost little given the pattern is now well established.

---

### 🔵 Suggestions

**6.** `types/resolved-price.md` heading is `# Schema: resolved price` — no backticks, contains a space — while every sibling Schema/Enum page uses `` # <Kind>: `Name` ``. Deliberate, since "resolved price" isn't an actual wire type name, but worth a one-line exception note in `04_PAGE_CONVENTIONS.md §1` so a future author doesn't "fix" it into a broken convention violation the other way.

**7.** `types/offer-state.md`'s sellability description covers `startTime`/`endTime` but not the legacy `time_window` (epoch-millis) field, which `Offer::isWithinSchedule()` also enforces when present (`app/Models/Offer.php:118-153`: "Both schedules are checked... an offer must satisfy whichever it carries, and both when it carries both"). It's unresolved from this review alone whether `time_window` is reachable through the new `offers[]` write path this ticket documents, or is populated only on legacy-migrated rows outside that path — worth a follow-up check rather than a blocking claim either way, since asserting it wrong would be exactly the kind of undercooked verification this ticket exists to prevent.

**8.** Provenance-marker punctuation (`**(Appning)**` inline vs. `**(Appning.)**` paragraph-leading) is intentional and already documented in `04_PAGE_CONVENTIONS.md §4`, added during the Phase 8 pass — no action needed, noted only because it was the kind of thing this review specifically went looking for and found already handled.

---

### 💡 Praise

- **The claim ledger earned its keep.** It didn't just document verification after the fact — it caught the `latencyTolerance: LATENCY_SENSITIVE` example bug (a real, previously undetected divergence in a document the original audit certified as divergence-free) *during* implementation, and it made this independent review materially faster: every claim in §2 above was checked by reading the cited `file:line` directly rather than re-deriving the whole contract from scratch. That's the mechanism working as designed.
- **ADR-003's availability marker** is a genuinely good resolution to a real bind (flag-gated endpoints, unknown production state) — it makes the page correct under either flag value instead of gambling on one, and the finding in #5 above is about a different set of pages, not this pattern.
- **The `DRAFT`-state self-correction during Phase 4/5** (initially documented as a 400, corrected to "passes validation, fails 409" after reading the request class instead of assuming) is exactly the discipline this ticket asked for, applied to the implementer's own draft, not just to the original audit.
- **"Your client must" framing** for the two service-unenforced obligations found (`NO_LONGER_AVAILABLE` hiding, EEA display) is the right instinct — flagging what the server does *not* do is as important as documenting what it does. One of the two (EEA) needs a content fix per finding #1, but the framing pattern itself is correct and should be kept.

---

## 3. Test Quality Review

There are no executable tests in this repository; "tests" here means the three verification scripts plus the claim ledger's citation discipline.

- **Critical paths covered:** yes — every endpoint's success and error paths are documented and every documented number has a ledger citation.
- **Edge cases:** generally well covered (wildcard combinations, same-state no-ops, duplicate detection, the non-regression combined-limit behaviour). The one material gap found is #3 above (an edge case in the *ledger's own* claim, not just the page).
- **Blind spots in the harness itself, found by this review:**
  - `check-links.sh` only recognizes `](...)` syntax, so a plain-code-formatted forward reference that was never turned into a real link (#2) is invisible to it. A cheap improvement: also flag any inline `` `word` `` immediately following "See " that isn't part of a link, as a warning (not necessarily a hard failure, to avoid false positives).
  - The ledger's correctness depends entirely on the citation being read carefully at capture time; nothing mechanical catches an incomplete-but-plausible claim like #3. This is a known, stated limitation in `04_CLAIM_LEDGER.md`'s own re-verification instructions ("a wrong number copied identically into both page and ledger passes every check") — the instructions were right to flag this as a residual risk, and this review is the confirming instance of it happening once, on a rule rather than a number.
  - No check enforces per-page structural consistency (e.g., "every method page has a Sandbox line") beyond the fixed skeleton in §1 of the conventions doc — #4 is a case where a convention existed for the *first* page written but wasn't mechanically propagated.
- **Mocking / over-testing:** not applicable to this deliverable.

---

## Review Summary

| Category | Count |
|---|---|
| 🔴 Critical | 1 |
| 🟡 Important | 4 |
| 🔵 Suggestions | 3 |
| 💡 Praise | 4 |

## Verdict: ⚠ NEEDS REVISION

The deliverable is substantively strong — 135 independently-citable claims, three passing verification scripts, a real bug caught in previously-certified content, and a defensible architecture for the two hardest open questions (flag-gated endpoints, an unwired integration flow). But finding #1 is a compliance-relevant inaccuracy in published, external-facing documentation, on a topic the source material states unambiguously and that was available throughout this implementation. It must be fixed before merge.

### Required Changes (block merge)
1. **Finding #1 (Critical).** Correct the EEA section: state "no mention of the offer" rather than "no strikethrough" alone, and make the two country lists findable from the documentation (inline, or added to `types/withdrawal-right-type.md`).
2. **Finding #2.** Turn the dead reference in `types/offer-token.md` into a real link to `offer-token-flow.md`.
3. **Finding #3.** Add the `VOIDED`-purchase exclusion to the redemption-count rule, on both the page and ledger row `P7-07`.
4. **Finding #4.** Add the sandbox host line to the six endpoint pages missing it (or explicitly scope it to first-page-only and say so in the conventions doc).
5. **Finding #5.** Correct the "cross-linked" claim in the closing summary, or add the four missing product-level pages — pick one and make the artifact match the claim.

### Recommendations (non-blocking)
1. Harden `check-links.sh` to flag a bare-code forward reference following "See " (§3).
2. Resolve whether `time_window` gates sellability on the new write path (#7) and add a line to `types/offer-state.md` if so.
3. Add the resolved-price heading exception to `04_PAGE_CONVENTIONS.md §1` (#6).
