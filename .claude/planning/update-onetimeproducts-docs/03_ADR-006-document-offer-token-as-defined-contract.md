# ADR-006: Document `offer_token` as a defined contract, in exact tense

## Status: Accepted
## Date: 2026-09-03

## Context

The ticket asks for `offer_token` — "how it is derived and what a client should do with it". Research found the two halves of that flow are in very different states:

**Live and observable today.** The token is minted on every catalogue read and every Console product-detail read, unconditionally, for both persisted and fallback-synthesised offers. Its format is fixed (`otk_` + 32 base64url characters, 36 total), it is a one-way HMAC over three public ids, it carries no expiry, and it is stable across reads for the same offer and secret. An integrator can see it right now.

**Defined but not exercised.** The purchase-time half — send the token, have it resolved to an offer identity, have the per-buyer redemption cap applied — is fully implemented on the receiving side but **no shipped broker forwards the token to this service**. The newer broker's resolution path is merged behind a flag defaulting to `false`; the legacy broker has no resolution code and rejects every real token. A code comment even names a broker constant that does not exist.

So a present-tense "send `offer_token` and the server resolves it" would describe something that currently happens for nobody, while omitting the flow would fail the ticket and leave the visible field unexplained.

## Decision

Document the token in two clearly separated registers, and never blur them.

1. **What it is** — present tense, unqualified, because it is all observably true now: format, derivation inputs (product, purchase option, offer), one-way and non-reversible, no embedded expiry, stable across reads, which responses carry it and which do not. Explicitly: it is **not** a signed price and **not** an authorisation token — it names an offer, and trust comes from the catalogue being the price authority.
2. **How it is used** — described as *the defined contract* for purchase-time resolution, with a single honest status line stating that no broker forwards it yet, so sending it has no effect today. The client rules are published as rules, because they are what a broker integrator must obey when they do wire it up:
   - Read `price.value` with `price.currency`; **never** `price.micros` — scale differs between services and misreading it mis-prices by 100×.
   - Parse `price.value` as a decimal; do **not** assume two decimal places.
   - There is **no** token-lookup endpoint, and none is planned; a single-id catalogue read is the mechanism.
   - Do **not** cache a resolved token or a catalogue response across requests — freshness is the expiry mechanism.
   - **Fail closed**: an unresolvable token must reject the purchase, never fall back to a client-supplied price.
   - "This offer ended" and "this token is invalid" are indistinguishable by construction — surface one message.
3. **No internal state is published**: no flag names, no branch or PR numbers, no environment variables, no secret-configuration detail, no latency target (none has been measured). Per ADR-005.

The redemption cap is documented on the same principle: Google's field and range, range-checked on write, **counted per buyer at purchase time**, and described as a merchandising control — explicitly **not** a security control, since a caller that omits the token stays out of the count.

## Alternatives Considered

| Option | Pros | Cons |
|---|---|---|
| **Split registers: "what it is" present tense, "how it is used" as defined contract with a status line** (chosen) | Every sentence true; the visible field gets explained; a broker integrator gets the rules before wiring, which is when they need them; ticket criterion met | Requires disciplined tense; the status line will need removing later |
| Present tense throughout | Reads confidently; simplest | Describes a flow that currently does nothing for any caller — the same class of error as the stale claims this ticket is fixing |
| Future tense throughout ("will be resolved") | Cannot overstate | Wrong about the half that is live and visible today; readers would ignore a field they can already see in responses |
| Omit the usage half until a broker forwards it | Zero risk of overstatement | Fails the ticket; leaves an unexplained 36-character string in every catalogue response; the rules that prevent a 100× mis-pricing would stay unpublished precisely while integrators are building |
| Publish the flag name so readers can check | Transparent | Internal configuration, not actionable by an external reader (ADR-005) |

## Consequences

- **Positive:** the field a reader can already see is explained; the rules that prevent real, expensive mistakes (micros scale, caching a stale price, falling back to a client price) are published before anyone needs them; nothing is overstated.
- **Negative:** one status line will become wrong when a broker ships forwarding, and must be removed then — recorded as a follow-up on the ticket.
- **Risks:** a reader may implement against the contract and find nothing happens end-to-end. That is why the status line is explicit rather than a footnote. The opposite risk — silence — is worse: a broker integrator reading `price.micros` and charging 100× is a live, expensive failure mode the source code specifically warns about.

## References

- `02_CODE_RESEARCH.md` §4.6 (`offer_token`: derivation, exposure, both halves of the flow, ADR-0139's corrections to ADR-0136), §5.6 (documenting an unwired flow), §7.2 decision 6
- Jira PAY-1889 item 4, and the research comment's question 2
