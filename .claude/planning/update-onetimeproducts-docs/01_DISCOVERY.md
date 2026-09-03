# Discovery: update-onetimeproducts-docs

## Summary
This task updates the `monetization.onetimeproducts` documentation in this repository. The documentation is six months old. It must show the fields and limits that shipped since March 2026. The task also updates Jira ticket PAY-1889 with progress notes.

## Problem Statement
The `docs/appning/android-publisher/monetization.onetimeproducts/` documentation was last audited at commit `d1b25c8`, dated 2026-03-17. Since that date, the backend added many features. The documentation does not show these features. An integrator who reads this documentation today gets an incomplete and outdated picture of the API.

The audit behind PAY-1889 found the current documentation to be 100% correct for what it covers. The problem is not wrong content. The problem is missing content.

## Success Criteria
- [ ] Every cap enforced in `BatchUpdateItem.php` appears in the documentation, with the same number.
- [ ] The per-region offer pricing model (`regionalPricingAndAvailabilityConfigs[]`, one of `noOverride` / `relativeDiscount` / `absoluteDiscount`) is documented.
- [ ] The offer resource and its lifecycle endpoints (`:activate`, `:deactivate`, `:batchUpdateStates`, `:batchDelete`, `:batchGet`) are documented.
- [ ] The `offer_token` field is documented: what it is and what a client must do with it.
- [ ] Purchase-option state transition endpoints (`:batchUpdateStates`, per-product and cross-product) are documented.
- [ ] The Appning-only `purchaseOptions[].type` field and its asymmetric validation against Google's `buyOption` / `rentOption` union are documented, with the reason for the difference.
- [ ] Fields that are stored but not enforced (`redemptionLimit`, `new_regions_config`, `multi_quantity_enabled`) are marked as such in the docs.
- [ ] No previously correct statement is changed without a source-code check first.
- [ ] Jira ticket PAY-1889 carries a comment that records the source-of-truth branch and links the delivered documentation changes.

## Scope
### In Scope
- Update `docs/appning/android-publisher/monetization.onetimeproducts/monetization.onetimeproducts.md` (resource + nested types) and `batchUpdate.md` (method) to match the current contract.
- Add new `types/` pages for any new referenced schema or enum (for example the offer resource, offer states, the pricing-override union).
- Add or update pages for the offer lifecycle endpoints and purchase-option state endpoints, following this repository's existing per-method page pattern.
- Cross-check every field, cap, and behavior claim against the source code before writing it.
- Update the `README.md` "Covered sub-links" list and the `docs/.../README.md` "Structure" list to add new pages.
- Post a summary comment on PAY-1889.

### Out of Scope
- Changes to the actual API implementation (`web-product-service-laravel`). This is a documentation-only task.
- The Python client repository (`appning-api-python-client`) — tracked separately under PAY-1888 (D1). Coordinate, do not duplicate.
- Restyling the documentation format. The repository is a technical extraction of Google's documentation, reorganized locally. Keep that structure.
- Endpoints and fields that Google's V3 API defines but this backend does not implement (the existing docs already list six such methods as "not implemented" — keep that pattern, do not invent new coverage).

## Source Context

- History File: none found for this issue.
- Raw Input: Jira ticket [PAY-1889](https://faurecia-aptoide.atlassian.net/browse/PAY-1889), "D2 — api-documentation: add the fields and limits shipped since March 2026".

This discovery phase reads the Jira ticket directly (no separate `/create-history` product-history document exists yet for this issue) and expands it into a scoped, verified technical starting point.

## Stakeholders
- Users: External and internal developers who integrate with the Appning `monetization.onetimeproducts` API.
- Teams: Payments team (repository owner), D1 owner (Python client, PAY-1888, coordinate only).
- Systems: `api-documentation` (this repo, the deliverable), `web-product-service-laravel` (source of truth for behavior), `appning-documentation` (a separate portal repo that appears to vendor a copy of these same doc pages — confirm during `/research` whether it needs a matching update; out of scope unless confirmed).

## Risk Assessment
**Level:** Medium
**Justification:** No code runs and no user-facing system is touched, so the blast radius of a mistake is low. But the ticket itself warns that a wrong statement is worse than a missing one ("Do not correct anything already in it without checking the code first"), and discovery found that the obvious source branch (`main`) is stale by 353 commits against the actual current branch (`staging`). Using the wrong branch during `/research` would silently reproduce the exact failure mode the ticket exists to fix: documentation that looks trustworthy but is wrong.

## Dependencies
- **Critical — branch selection.** `web-product-service-laravel` `main` is at commit `9fe6ed6` and does **not** contain any of the features PAY-1889 lists as missing (confirmed: `main` has none of `PURCHASE_OPTIONS_MAX`, `OFFERS_PER_OPTION_MAX`, `REGIONAL_CONFIGS_MAX`, `OFFER_TAGS_MAX`, `REDEMPTION_LIMIT_MAX`, the offer resource, or `offer_token`). The local `staging` branch was also 9 commits stale. `origin/staging` (fetched during discovery, tip `c4dd77a`) **does** contain all four caps named in the ticket, at the exact line range the ticket cites (`app/Dto/Internal/AndroidPublisher/BatchUpdateItem.php` lines 118–195), plus the offer resource, `offer_token`, and per-region pricing work. **`/research` must read `web-product-service-laravel` at `origin/staging`, not `main`.**
- `docs/architecture/one-time-products.md` inside `web-product-service-laravel` (present on `origin/staging`, absent on `main`) documents the `type` field caveat the ticket calls out — a design-intent source to read alongside the code.
- PAY-1888 (D1, Python client) — coordinate the offer-token and per-region pricing writeup so both docs describe the same model.
- ADRs referenced by the ticket and found in the `staging` history: 0121–0125, 0130 (implied by PAY-1819/1820/1821), 0135–0143, 0145, 0148, 0150–0152, 0156–0157, 0160–0162 — `/research` should read the ones relevant to each success criterion rather than all of them.

## Estimated Complexity
**Size:** M
**Reasoning:** No code changes, one repository, a well-established page pattern to follow. But the amount of new material is large — six months of shipped work across pricing, offers, and lifecycle endpoints — and every claim needs a source-code check, which is the slow part.

## Detected Tech Stack

### Languages & Frameworks
| Technology | Version | Expert Command |
|------------|---------|-----------------|
| Markdown | — | `/language/software-engineer-pro` (fallback — no code-specific expert applies) |
| Bash (`test-endpoint.sh`) | — | `/language/software-engineer-pro` (fallback) |

No `package.json`, `tsconfig.json`, `composer.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, or `go.mod` was found. This repository holds no runtime application code — it is a documentation-only repository, matching the "no runtime code" note in the project's own `CLAUDE.md`.

### Infrastructure
| Technology | Expert Command |
|------------|-----------------|
| None detected | — |

No `*.tf`, `Dockerfile`, `docker-compose.yml`, Kubernetes, or cloud-provider markers were found.

### Quality Tooling
| Tool | Status |
|------|--------|
| Linter | ✗ Missing (no markdown linter configured) |
| Formatter | ✗ Missing |
| Test Runner | ✗ Missing (`test-endpoint.sh` is a manual, ad-hoc JWT/curl smoke script, not an automated test suite) |
| CI/CD | ✗ Missing (no `.github/workflows/`) |
| Pre-commit Hooks | ✗ Missing |

## Repository Map

```
api-documentation/
  README.md                          — API overview, JWT auth model, endpoint index, test-endpoint.sh usage
  test-endpoint.sh                   — manual smoke-test script (JWT signing + curl call)
  docs/
    appning/
      android-publisher/
        monetization.onetimeproducts/
          README.md                  — page index for this method group
          batchUpdate.md             — method doc: monetization.onetimeproducts.batchUpdate
          monetization.onetimeproducts.md — resource doc: OneTimeProduct + nested types
          types/
            money.md
            offer-tag.md
            product-update-latency-tolerance.md
            regional-product-age-rating-info.md
            regions-version.md
            restricted-payment-countries.md
            streaming-tax-type.md
            tax-tier.md
            withdrawal-right-type.md
```

**Files:** 13 markdown | 1 shell script | 0 config
**Primary format:** Markdown, one page per API method/resource/type, Google-API-doc style
**Key entry points:** `README.md` (repo root), `docs/.../monetization.onetimeproducts/README.md` (section index)

> Generated automatically during discovery. Run `/repo-map` to refresh.

## Symbol Index

Not applicable — this repository has no source-code symbols (no functions, classes, or types to index). The closest equivalent is the page-to-page reference graph, which is small enough to read directly in the Repository Map above and in each page's own "Local references" / "Covered sub-links" section.

> Generated alongside repo map. Run `/repo-map` to refresh.

### Missing Quality Tooling Recommendations
- No linter → consider a markdown linter if the team wants automated style checks, but this is optional for a small, hand-curated doc set.
- No CI → optional; not required for this ticket.
- General quality check → not needed; this ticket's own acceptance criteria (source-code cross-check on every claim) are the real quality gate here.

### Fallback Expert Command
No specific language or cloud expert matches a documentation-only repository. Use **`/language/software-engineer-pro`** for structural/consistency judgment calls (for example, how to slot new pages into the existing method/resource/types pattern) if needed. Most of the actual work is source-code verification against `web-product-service-laravel` at `origin/staging`, not software engineering in this repository.
