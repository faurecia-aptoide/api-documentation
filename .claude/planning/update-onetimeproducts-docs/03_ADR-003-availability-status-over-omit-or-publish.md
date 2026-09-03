# ADR-003: State per-endpoint availability instead of choosing between omit and publish

## Status: Accepted
## Date: 2026-09-03

## Context

Every endpoint this ticket asks us to document sits on the Console surface, and **the whole Console surface is gated by two feature flags that default to `false`**. The flags gate at *route registration*, so a disabled endpoint returns **404**, not a meaningful error. Their deployed values are not in any repository — no `.env.example` entry exists — so this cannot be resolved by reading code.

That produced an apparent binary:

- **Publish anyway**, and risk documenting endpoints that 404 in production. The source repo states the principle we would be breaking, about a different endpoint: *"publishing a contract for an endpoint that 404s is worse than omitting it."*
- **Omit until confirmed**, and fail the ticket's acceptance criteria, which explicitly require the offer resource, its lifecycle endpoints and the purchase-option state transitions to be documented.

Both options are wrong, and both stake the correctness of a published document on a deployment fact that changes without touching this repository. The question was asked on the ticket; the design should not *depend* on the answer.

## Decision

Neither omit nor silently publish. **Make availability an explicit, stated property of each endpoint page**, so the page is correct under either flag state.

- Each endpoint page carries an availability line directly under its surface preamble.
- Two values only:
  - **Generally available** — reachable for any authorised caller.
  - **Limited availability** — "This endpoint is being rolled out. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access." No flag name, no environment variable, no internal deploy state.
- The existing `<details>` "not implemented" convention is reserved for endpoints that **do not exist in code at all** (`:cancel`, `patch`, `batchGet` at product level). Gated-but-implemented is a different state and gets a different treatment.
- Default, absent an answer from the team: mark the eleven Console endpoints **limited availability**. If confirmation arrives that both flags are on in production, this is a one-line-per-page edit to "generally available".

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Explicit availability marker** (chosen) | Correct under either flag state; ticket criteria met; a 404 becomes an explained outcome instead of a contradiction; cheap to flip later | Introduces a status vocabulary; "limited availability" is slightly less confident than a fully-GA page |
| Publish with no caveat | Simplest; reads confidently | If the flags are off, every one of eleven pages describes an endpoint that 404s — the precise failure the source repo warns against, published to external developers |
| Omit until the flags are confirmed | Cannot mislead | Fails the ticket; blocks the deliverable on an answer that may not come; and the work would have to be redone later anyway |
| Publish behind the `<details>` "not implemented" block | Uses an existing convention; no new vocabulary | Actively false — these endpoints *are* implemented, tested and drift-guarded. Conflates "does not exist" with "not switched on for you", which are different things for an integrator |
| Document the flag names so a reader can ask precisely | Maximum transparency | Leaks internal configuration to an external audience (see ADR-005); a reader cannot act on a flag name anyway |

## Consequences

- **Positive:** the deliverable stops depending on an unanswerable question; a reader who hits a 404 has an explanation and an action; the ticket's acceptance criteria are met without publishing a probable falsehood; flipping to GA later is trivial and page-local.
- **Negative:** an extra status line on eleven pages; if the flags *are* on, those pages are more cautious than they needed to be for a while.
- **Risks:** a stale "limited availability" marker left behind after the flags are enabled would understate the API. Mitigated by recording the flip as a follow-up item on the ticket, tied to the same question that produced this ADR — and understating availability is the safe direction of error.

## References

- `02_CODE_RESEARCH.md` §5.1 (highest risk: endpoints that may not answer), §7.2 decision 1
- Source precedent: the console OpenAPI spec's "Not in this spec" note, which omits a de-scoped endpoint on exactly this reasoning
- Jira PAY-1889, research comment, question 1
