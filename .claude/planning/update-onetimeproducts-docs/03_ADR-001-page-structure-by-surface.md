# ADR-001: Split pages by API surface, additively

## Status: Accepted
## Date: 2026-09-03

## Context

The ticket asks for the offer resource, its lifecycle endpoints and purchase-option state transitions to be documented. Research established that all of those live on a **different API surface** from the one this repository currently documents:

| | Partner / v3 (documented today) | Seller / Console (to be added) |
|---|---|---|
| Path | `/androidpublisher/v3/applications/{packageName}/…` | `/sellers/{uid}/inapp/oneTimeProducts/…` |
| Authorisation | package-scoped | seller-scoped, path `{uid}` must match the token |
| Error envelope | `{"error":{…}}` | `{code,path,text,data}` |
| Pagination | — | numbered pages / `pageToken` |
| Batch semantics | Google-style | all-or-nothing |
| `state` on write | accepted and ignored | rejected |

Existing page paths are also load-bearing: they are live portal URLs, they are listed in the root `README.md` endpoint table, and PAY-1888 (D1) intends to link here.

## Decision

Document each surface in its own directory, and make every change **additive**:

- New directories `offers/` and `purchase-options/` under the existing `monetization.onetimeproducts/` group, each with its own `README.md` index.
- One page per endpoint, following the existing method-page shape.
- A **surface preamble** block on every page — path shape, auth, error envelope, pagination — placed directly after the `Adapted from:` line.
- **No existing file is moved or renamed.** `batchUpdate.md` and `monetization.onetimeproducts.md` are extended in place.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Directory per surface, additive** (chosen) | Keeps one-page-per-method, which both this repo and Google use; new pages appear in portal navigation automatically; no URL breakage; scales to a third surface | ~18 new files; two index lists to keep in step with the tree |
| One "what changed since March 2026" page | Cheapest to write; easy to review as a single diff | Fights the repository's structure; ages into a changelog nobody reads; ticket explicitly says keep the existing organisation |
| Extend the two existing pages only | No new files; smallest navigation footprint | `monetization.onetimeproducts.md` is already 226 lines and would roughly triple; mixes two auth models and two error envelopes on one page — the exact conflation risk research flagged |
| Restructure into `v3/` + `console/` top-level dirs | Cleanest conceptual split | Moves existing pages, breaking live portal URLs, the root endpoint table and any external links, including D1's. Rejected on that basis alone |

## Consequences

- **Positive:** surfaces cannot blur; each page is a lookup target; page count grows in a predictable pattern; the portal needs no change; existing links keep working.
- **Negative:** two hand-maintained index lists (`README.md` structure list, root endpoint table) can drift from the file tree — mitigated by making index updates part of the per-page definition of done.
- **Risks:** the filename-as-navigation-label behaviour means a poorly chosen filename is a user-visible defect; page names are fixed in the spec rather than chosen during writing. Directory depth beyond two levels below the method group would read badly in the navigation tree, which caps how far this pattern extends.

## References

- `02_CODE_RESEARCH.md` §2.1 (publishing pipeline), §2.2 (two surfaces), §5.4 (conflation risk), §7.1 (proposed tree)
- Portal behaviour: `appning-documentation` `ApiDocumentationController::show()`, `DirectoryTreeService::buildTree()`
