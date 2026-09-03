# ADR-005: Verify against code, publish no internal identifiers — keep a claim ledger instead

## Status: Accepted
## Date: 2026-09-03

## Context

The ticket's central instruction is *"Verify every statement against the code as you go. The code is the truth"*, and its acceptance criteria require every enforced cap to appear with the same number. That creates a traceability need: a reviewer must be able to check that a published number came from somewhere real.

The obvious way to satisfy that is to cite the code in the page — "max 55 characters (`BatchUpdateItem.php:63`)". That is wrong for this deliverable, for two independent reasons:

1. **The audience is external.** These pages are served to third-party developers at `developers.appning.com`. Internal class names, file paths, line numbers, service names, ADR numbers, feature-flag names, branch names and commit hashes tell an integrator nothing actionable and disclose internal structure. The source repo already applies this discipline to itself: the readiness check for the offer-token secret deliberately never emits the value, its length, or a fingerprint.
2. **Line numbers rot faster than the facts.** Research found line-number drift inside the source repo's own ADRs within days — one ADR cited a line that had already moved by 6. A page full of `file:line` citations would be visibly stale within a sprint while its actual content stayed correct, training readers to distrust it.

But dropping citations entirely loses the audit trail the ticket asks for.

## Decision

Separate the two concerns.

- **Published pages** state facts in the reader's terms: the number, the rule, the error the caller will see, whose rule it is (ADR-002). No file paths, class names, line numbers, ADR numbers, flag names, branch names, commit hashes, internal service names or database column names. Where an internal name *is* the wire contract — a JSON field name, an error `code` string, an enum value — it is published, because the caller sends or receives it.
- **`04_CLAIM_LEDGER.md`**, in the planning directory and never deployed, carries one row per published claim:

  | Page | Claim | Provenance | Enforced | Source (`file:line` @ `c4dd77a`) | Status |
  |---|---|---|---|---|---|

- **No page ships a claim absent from the ledger.** The ledger is the review instrument for the acceptance criteria and the re-verification instrument when the code next moves.
- Ticket assertions the code contradicts are recorded `rejected` with evidence, and raised on the ticket rather than published.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Facts in pages, citations in an internal ledger** (chosen) | Clean external pages; full auditability; re-verification is cheap and targeted; nothing leaks | A second artefact to maintain; the ledger can drift from the pages if updated carelessly |
| Cite `file:line` inline in published pages | Maximum transparency; trivially reviewable | Leaks internal structure to third parties; rots within weeks; clutters a reference document; unusable by the actual audience |
| HTML comments in the Markdown | Invisible to readers; travels with the page | Ships to the portal and is readable in page source — leaks by any reasonable definition |
| No citations anywhere | Cleanest pages | Fails the ticket's verification criterion; makes re-verification a full re-audit; every number becomes unfalsifiable |
| Cite ADR numbers only, not files | Shorter; stable identifiers | Still internal; and research showed the ADRs themselves are unreliable — three in a correcting chain, and several stale against their own code |

## Consequences

- **Positive:** pages read as product documentation rather than internal notes; the acceptance criteria become mechanically checkable; when the code next moves, the ledger says exactly which claims to re-check instead of requiring another full audit; the disclosure question is settled once rather than per page.
- **Negative:** the ledger must be updated in the same commit as the page it describes, or it becomes a second stale source — the failure mode this whole ticket is about. It is therefore part of the per-page definition of done, not a final pass.
- **Risks:** a ledger nobody reads after this ticket is dead weight. Its value depends on being the first stop next time the docs are audited; that intent is recorded on the ticket so the next auditor knows it exists.

## References

- `02_CODE_RESEARCH.md` §6.3 (nine stale in-repo prose claims; ADR line-number drift), §5.7 (both OpenAPI specs stale)
- Ticket instruction: "Verify every statement against the code as you go. The code is the truth."
