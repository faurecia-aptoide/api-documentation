# ADR-004: Keep the "not implemented" list and scope it to its surface

## Status: Accepted
## Date: 2026-09-03

## Context

`monetization.onetimeproducts.md` ends with a collapsed `<details>` block listing six Google methods as "not implemented at the moment": `batchDelete`, `batchGet`, `delete`, `get`, `list`, `patch`.

The audit that produced this ticket found the whole document divergence-free, and the ticket instructs: *"Do not 'correct' anything already in it without checking the code first"* and *"Nothing previously correct has been changed without a code check."*

Checking the code produced an awkward result. Four of the six — `list`, `get`, `batchDelete`, `delete` — **are now implemented**, but on the seller-scoped Console surface, with different paths, a different auth model and a different error envelope. On the `androidpublisher/v3` surface that this page documents, they remain absent: only `:batchUpdate` exists there. Only two of the six are absent everywhere (`batchGet`, `patch`), plus two offer-level methods (`offers.cancel`, `offers.batchUpdate`).

So the list is **neither correct nor incorrect as written** — it is unscoped. A reader on this page reasonably takes it as "the Appning API does not offer these", which is now false. Delete it and the page loses true information about the v3 surface. Rewrite it as "implemented" and the page becomes false in the other direction, because those methods are not reachable at the paths this page documents.

## Decision

**Keep the list. Scope it explicitly to the v3 surface. Link to where the implemented ones live.**

- Retitle from "Other methods - not implemented at the moment" to name the surface, e.g. *"Other Google methods — not available on this surface"*.
- Split it into two groups:
  - **Available on the seller-scoped surface**, with a relative link per method to its new page: `list`, `get`, `batchDelete`, `delete`.
  - **Not implemented anywhere**, with the reason where one is recorded: `batchGet`, `patch`, and at offer level `cancel` (deliberate — Google's `cancel` targets a pre-order-only state, and pre-orders are rejected on write) and `batchUpdate` (unnecessary — `oneTimeProducts:batchUpdate` already writes offers).
- Keep the `<details>` collapse, which is an existing convention on the page.

This is the one edit in the ticket that changes text the audit certified as correct, so it is recorded as a decision with its reasoning rather than made silently.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Keep, scope, and cross-link** (chosen) | Every statement true; preserves information the page already carried; guides a reader to the endpoint they actually want; makes the two-surface split legible at the point of confusion | Modifies audit-certified text; needs the surface named accurately or it trades one ambiguity for another |
| Leave the list untouched | Honours "nothing previously correct has been changed" most literally | Leaves a reader believing four implemented methods do not exist. Literal compliance, substantive failure |
| Delete the list | No false statement remains | Loses true, useful information about the v3 surface, and silently drops the deliberate absences (`cancel`, `patch`) that a reader may specifically look for |
| Mark all six "implemented — see Console" | Reflects that most now exist | False for `batchGet` and `patch`, which exist nowhere, and misleading for the rest, which are not at these paths |

## Consequences

- **Positive:** the page stops implying a capability gap that no longer exists, while keeping the genuine gaps visible with their reasons; the cross-links turn the surface split from a trap into navigation.
- **Negative:** touches text the audit blessed, which must be called out on the ticket rather than buried in a diff — the reviewer needs to see it deliberately.
- **Risks:** the reasoning behind the original six could not be verified, because the audit artefacts it came from (`05-batch-update.md`, `08-divergences.md`) are not in any local repository and were requested on the ticket. If they turn out to have scoped the list some other way, this decision may need revisiting.

## Implementation note (added during review, 2026-09-03)

The decision above says the available-on-the-seller-surface group would be listed "with a relative link per method". **That was only delivered for the offer- and purchase-option-level methods**, which each have a page. The four **product**-level methods (`list`, `get`, `delete`, `batchDelete`) are named in plain text with no link, because no pages for them exist — writing them was never in the ticket's scope and was correctly left off the implementation plan.

The page now says so explicitly rather than leaving a reader to wonder why four announced methods lead nowhere. Building them out is recorded as a follow-up, not a silent omission.

The wording "cross-linked" in the ticket's closing comment overstated this and was corrected.

## References

- `02_CODE_RESEARCH.md` §4.3 (Google method coverage), §7.2 decision 2
- Route inventory verified in `routes/api.php` at `origin/staging` `c4dd77a`
- Jira PAY-1889 acceptance criterion: "Nothing previously correct has been changed without a code check"
