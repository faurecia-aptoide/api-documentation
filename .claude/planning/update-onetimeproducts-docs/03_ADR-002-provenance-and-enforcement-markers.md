# ADR-002: Mark provenance and enforcement on every field and cap

## Status: Accepted
## Date: 2026-09-03

## Context

Every page in this repository opens with `Adapted from:` and a Google URL, and describes itself as a technical extraction of Google's documentation. That framing makes an unmarked statement read as *Google's rule*. Three things make that dangerous here:

1. **Three of the caps this ticket asks us to publish are ours, not Google's.** The source code says so under an explicit heading — "These are OURS, not Google's — do not cite them as Google limits" — and records why: this codebase already shipped a validator that **rejected input Google accepts** because one of our own design numbers had been recorded as Google's (the `redemptionLimit` 1–50 incident, ADR-0134). The same correction was later applied to the rental-period matrix and to the 100-option ceiling.
2. **The ticket asks for a third category** — fields that are "stored but not enforced", which "an integrator must not read as controls". Research confirmed two of these (`newRegionsConfig`, `multiQuantityEnabled`) and found one had graduated (`redemptionLimit` is now enforced, at purchase time).
3. **Some rules are ours *and stricter* than Google's** — `DRAFT`-only deletability, the four rental-period pairings. These must be kept but must not be presented as parity.

So a reader needs to distinguish four things about any given item, and prose alone has repeatedly failed to carry that distinction inside this ecosystem.

## Decision

Introduce two orthogonal markers as first-class page furniture.

**Provenance**, one per field / enum value / cap:

| Marker | Meaning |
|---|---|
| *(unmarked)* | Google's field, Google's rule — the default, keeping pages uncluttered |
| **Appning** | our field or our rule; Google publishes nothing here |
| **Appning, stricter** | Google's field, our tighter rule; not parity |
| **Accepted, not enforced** | accepted and stored, but nothing acts on it — do not use as a control |

**Enforcement**, in a per-method table: cap · value · applies to · whose rule · *when* enforced (request boundary / write time / purchase time / not enforced).

`redemptionLimit` is the worked example that needs all of it: Google's field, Google's 1–50 range, range-checked at write time, **count enforced at purchase time**, and explicitly a merchandising control rather than a security control.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Two markers + enforcement table** (chosen) | Carries the ticket's "stored but not enforced" criterion and the provenance risk in one mechanism; scannable; degrades gracefully as plain Markdown | Adds visual weight; every new field needs a provenance judgement |
| Prose sentences per field ("this is an Appning extension") | No new convention; reads naturally | Research found nine in-repo prose claims contradicting their own code — prose is exactly what failed here; not scannable; easy to omit under editing pressure |
| A single "Divergences from Google" appendix page | One place to maintain; mirrors the source repo's numbered-divergence habit | A reader looking up one field does not read appendices; the information is needed at point of use |
| Mark only divergences, leave enforcement out | Smallest change satisfying the provenance risk | Misses the ticket's explicit "stored but not enforced" acceptance criterion, which is about enforcement, not provenance |

## Consequences

- **Positive:** satisfies two acceptance criteria with one device; makes the dangerous case (our cap read as Google's) visually impossible to miss; gives a reviewer something checkable per field rather than a prose judgement.
- **Negative:** a marker vocabulary is a convention future authors must learn and apply; an unmarked field is meaningful (it asserts "Google's"), so an author who forgets to mark an Appning field creates a *wrong* statement rather than an incomplete one.
- **Risks:** that failure mode — silence meaning "Google's" — is the same shape as the bug the ticket exists to fix. Mitigated by making provenance a required column in the claim ledger, so an unmarked field is an unfilled ledger cell rather than an invisible omission.

## References

- `02_CODE_RESEARCH.md` §5.3 (attributing our limits to Google), §3.3 (the three enforcement verdicts), §6.2 (how the source repo labels `OURS` / `TOLERATED` / `SPECIFIC`)
- Source: the "These are OURS, not Google's" block in the batch-update item parser; the rental-matrix provenance warning
