# Status: update-onetimeproducts-docs

**Risk:** Medium | **Updated:** 2026-09-03T15:05:00Z
**Stack:** Markdown documentation (no runtime code) — source of truth lives in a separate repo, `web-product-service-laravel` (PHP / Laravel), branch `origin/staging`

## Progress
- [x] Discovery - Completed
- [x] Research - Completed
- [x] Design - Completed
- [x] Planning - Completed
- [x] Implementation - Completed (20 new pages, 4 modified, 135 verified claims, 6 commits)
- [x] Review - APPROVED after fixes (1 critical + 4 important resolved; C3 found and fixed during the fix pass; all 3 recommendations closed)
- [x] Types-page audit - Completed (8 of 8 pages had findings — see 06_TYPES_PAGES_AUDIT.md)
  - Phase 1 Conventions + harness: ✓ Complete
  - Phase 2 Type pages: ✓ Complete (8 pages, 31 ledger rows)
  - Phase 3 v3 surface: ✓ Complete (2 pages patched, 47 ledger rows)
  - Phase 4 Offer resource + reads: ✓ Complete
  - Phase 5 Offer lifecycle writes: ✓ Complete (committed together — the offers index inherently lists both, 24 ledger rows)
  - Phase 6 Purchase-option states: ✓ Complete (3 pages, 15 ledger rows)
  - Phase 7 offer_token flow: ✓ Complete (1 page + EEA section, 18 ledger rows)
  - Phase 8 Verification + closure: ✓ Complete

### Verification results
| Gate | Result |
|---|---|
| Link check | PASS — every relative link resolves |
| Leakage check | PASS — no file paths, class names, ADR numbers, flag names, hashes or perf claims |
| Index parity | PASS — file tree matches both hand-maintained indexes |
| Ledger coverage | 135 `verified`, **0 `pending`**, 3 `rejected`, 0 empty provenance cells |
| Spot re-verification | **12/12** numbers re-derived from source independently of the ledger |
| Page budget (NFR-02) | PASS — largest page 18 KB / 380 lines against a 40 KB / 500-line budget |
| Renames (TR-16) | **0** across all six commits |
| Structural pass | PASS — every endpoint page states URL, auth, body, success and errors |
| Terminology / accessibility | PASS — fixed phrasings used; every table has a header row; no meaning by symbol alone |

### Follow-ups (not defects)
1. Flip the eleven "limited availability" markers to "generally available" once the Console flag values are confirmed — one line per page.
2. Remove the `offer_token` status line once a broker forwards the token.
3. No worked example of a full `offers[]` write payload. The repository's convention is placeholder JSON, so this is consistent rather than a gap, but an example page would help an integrator.
4. Offer to fix the nine stale prose claims in the source repository (separate ticket).
- [ ] Security - Not started
- [ ] Deploy - Not started
- [ ] Observe - Not started
- [ ] Retro - Not started

## Detected Stack
Documentation-only repository (Markdown + one Bash smoke-test script). No linter, formatter, test runner, or CI configured. No code-specific expert applies; the work is cross-checking documentation claims against PHP source in a sibling repository.

## Applicable Expert Commands
- `/language/software-engineer-pro` — fallback, for page-structure and consistency judgment calls only

## Key Decisions
- **Source-of-truth branch is `web-product-service-laravel` `origin/staging` (tip `c4dd77a`), not `main`.** `main` (`9fe6ed6`) is 353 commits behind and contains none of this feature set.
- Research, implementation and review all read the source through a **read-only detached git worktree of `origin/staging` at `c4dd77a`**, created under the local session scratchpad (path is machine-specific, so not recorded here).
  Re-create with `git worktree add --detach <local-path> c4dd77a` from `web-product-service-laravel`, and `git worktree remove <local-path>` when finished. Pin `c4dd77a` specifically: re-verifying against a newer tip would mix two contracts in one document.
- **Two of the ticket's three substantive claims are wrong** (verified in code):
  - `purchaseOptions[].type` is **rejected on key presence**, not accepted-and-conflicting (ADR-0135). The described asymmetry no longer exists in either direction, and the ticket's line citation points at the wrong section.
  - `redemptionLimit` **is enforced**, at purchase time, as of the branch-tip commit. It is dormant behind two gates and is explicitly not a security control. `newRegionsConfig` and `multiQuantityEnabled` do hold up as stored-only.
  - The caps claim (100/100/400/50) is **confirmed**.
- **The three big caps are ours, not Google's**, and the code carries an explicit warning not to cite them as Google limits — this repo has already shipped a validator that rejected input Google accepts for exactly that reason (ADR-0134). Provenance labelling is therefore a required design element.
- **There are two API surfaces.** The documented `:batchUpdate` is on `/androidpublisher/v3/...` with Google's error envelope; every endpoint the ticket asks for is seller-scoped under `/sellers/{uid}/...` with a different envelope, `seller.acl` scoping and numbered-page pagination. Pages must separate them.
- **The existing "six methods not implemented" list is surface-dependent, not simply wrong.** It stays true for the v3 surface. Rewriting it without naming the surface would replace one inaccuracy with another.
- **No portal change is needed.** `appning-documentation` serves this repo's Markdown at request time from a git-ignored directory populated at deploy. Filenames become navigation labels; the file tree becomes the URL tree.
- **Neither OpenAPI spec is usable as a source** — four verified schema drifts, with prose and schema disagreeing inside the same file.
- **In-repo prose lags its own code, repeatedly** — nine stale claims found across architecture notes, docblocks, route comments and both specs. Cite the parser, enum, route or migration; never an ADR or docblock.

## Found During Implementation
- **A second change to audit-certified text was necessary, and it is a divergence the audit missed.** The published request-body example on `batchUpdate.md` used `latencyTolerance: PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE`, which this service **rejects with 400** — it accepts only `…UNSPECIFIED` and `…LATENCY_TOLERANT`. The bullet "Default is latency-sensitive" was also wrong; the default is `UNSPECIFIED`. An integrator copying the documented example got an error. Corrected in Phase 3, recorded as C2 in the claim ledger, to be raised on the ticket.
- Forward links are deferred to the phase that creates their target, in both Phase 2 and Phase 3 — a page never links to a target that does not exist. Phases 4 and 6 add the links back into the resource page.

## Design Decisions (ADRs)
- **ADR-001 — Page structure by surface, additive.** Directory per surface (`offers/`, `purchase-options/`), one page per endpoint, surface preamble on every page. **No existing file is moved** — portal URLs mirror file paths, so a rename breaks live links and the root endpoint table.
- **ADR-002 — Provenance and enforcement markers.** Four-value provenance vocabulary (unmarked = Google's / **Appning** / **Appning, stricter** / **Accepted, not enforced**) plus a per-method enforcement table. Carries the "stored but not enforced" criterion and prevents citing our caps as Google's.
- **ADR-003 — Availability status instead of omit-or-publish.** Resolves the feature-flag blocker architecturally: each endpoint page states "generally available" or "limited availability" with a 404 explanation, so the page is correct whether or not the flags are on. Default is limited availability. No flag names published.
- **ADR-004 — Keep the "not implemented" list, scoped per surface.** It is unscoped rather than wrong: still true for v3, while four of six are implemented on the Console surface. Retitle, split into "available on the seller surface" (cross-linked) and "not implemented anywhere" (with reasons). The only edit to audit-certified text — called out deliberately.
- **ADR-005 — Verify against code, publish no internal identifiers.** Facts go in pages; `file:line` citations go in an internal `04_CLAIM_LEDGER.md` that is never deployed. Audience is external, and line numbers rot faster than facts.
- **ADR-006 — Document `offer_token` as a defined contract, in exact tense.** "What it is" in plain present tense (all observably true); "how it is used" as the defined contract with one status line noting no broker forwards it yet. Publishes the client rules that prevent a 100× mis-pricing.

## Resolved Since Research
1. ~~Console endpoints and the feature flags~~ → resolved by ADR-003; still worth confirming the deployed values to flip the markers.
2. ~~"Not implemented" list~~ → resolved by ADR-004.
3. ~~`offer_token` tense~~ → resolved by ADR-006.

Still outstanding, and asked on the ticket: the deployed flag values, whether the broker PR merged, and the two cited audit artefacts. None of them block Planning.

## Plan Summary
**8 phases, effort M.** One commit per phase. Ordering is interface-first: conventions and check scripts, then leaf type pages, then the pages that reference them, then verification.

| Phase | Milestone |
|---|---|
| 1 | Conventions + 3 check scripts (link, leakage, index parity); ledger opened with the 3 rejected ticket claims. No published change |
| 2 | 8 new `types/` pages — leaf contracts everything else links to |
| 3 | **v3 surface: the eleven caps, unknown-key rejection, `updateMask`, pricing union, ADR-004 list rewrite.** Highest value; shippable alone |
| 4 | Console surface opens: offer resource + `list` / `batchGet` |
| 5 | Offer lifecycle writes: `:activate`, `:deactivate`, `:batchUpdateStates`, `:batchDelete` |
| 6 | Purchase-option `:batchUpdateStates` (both variants) + `:batchDelete` |
| 7 | `offer_token` integration contract, `redemptionLimit` end to end, EEA obligation |
| 8 | Mechanical verification, 10-number spot re-verify, ticket closure |

**Revert boundaries:** Phases 4-7 together restore a coherent v3-only document. Phase 5 must not be reverted while Phase 4 stands (its index would list missing pages). Phase 3's not-implemented list cross-links into Phases 4-7 — the one cross-phase coupling, caught by the link check.

**Key constraint carried through every phase:** index updates ship in the same commit as the pages they list, and no existing file is ever moved — portal URLs mirror file paths.

## Follow-up raised

**PAY-1930** — `web-product-service-laravel`: correct nine in-repo docs that contradict their own code. 15 sites in 7 groups, each cited at `c4dd77a` and re-verified at filing time. Linked to PAY-1889 as related; does not block it. Includes two process suggestions beyond the cleanup: extend the console OpenAPI drift guard to schema shape (which is why group F survived it), and prefer a pointer over a paraphrase in docblocks.

## Artifacts
- 01_DISCOVERY.md
- 02_CODE_RESEARCH.md
- 03_ARCHITECTURE.md
- 03_ADR-001-page-structure-by-surface.md
- 03_ADR-002-provenance-and-enforcement-markers.md
- 03_ADR-003-availability-status-over-omit-or-publish.md
- 03_ADR-004-scope-not-implemented-list-per-surface.md
- 03_ADR-005-no-internal-identifiers-in-published-pages.md
- 03_ADR-006-document-offer-token-as-defined-contract.md
- 03_PROJECT_SPEC.md
- 04_IMPLEMENTATION_PLAN.md
- 04_CLAIM_LEDGER.md, 04_PAGE_CONVENTIONS.md, scripts/ — **created in Phase 1 of Implementation**
