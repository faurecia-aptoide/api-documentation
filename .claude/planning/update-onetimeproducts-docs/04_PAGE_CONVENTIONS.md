# Page Conventions: update-onetimeproducts-docs

Canonical blocks for every page written in Phases 2–7. Paste these verbatim and fill the placeholders — do not re-invent wording per page, or the pages drift from each other (NFR-08, NFR-09).

Internal to the planning directory. **Never deployed.**

---

## 1. Page skeleton

Order is fixed. Every new page has every block.

```markdown
# <Kind>: `<name>`

Adapted from:

- <Google reference URL>

<one-sentence description>

<SURFACE PREAMBLE>          <- endpoint pages only
<AVAILABILITY MARKER>       <- endpoint pages only

## <body sections>

## Local references

- [`<page>`](./<page>.md)
```

`<Kind>` is one of `Method`, `REST Resource`, `Schema`, `Enum` — matching the existing pages exactly.

---

## 2. Surface preamble

### 2a. Partner / v3 surface

```markdown
> **Surface:** partner API, `/androidpublisher/v3/…`.
> Authentication is the JWT Bearer model in the project [`README.md`](../../../../README.md#authentication-jwt-bearer).
> Errors use the Google envelope: `{"error": {"code", "message", "errors[]", "status"}}`.
```

### 2b. Seller / Console surface

```markdown
> **Surface:** seller management API, `/sellers/{uid}/…`.
> Authentication is the same JWT Bearer model in the project [`README.md`](../../../../README.md#authentication-jwt-bearer), and the `{uid}` in the path must be the seller the token belongs to — any mismatch returns the same `403`, whether the seller exists or not.
> Errors use the standard envelope: `{"code", "path", "text", "data"}` — **not** the Google envelope used by `/androidpublisher/v3/…`.
```

Relative depth in the `README.md` link changes by directory: `../../../../README.md` from the group root, `../../../../../README.md` from `offers/` and `purchase-options/`. **The link check catches a wrong depth**, so paste and let the check confirm.

---

## 3. Availability marker (ADR-003)

Exactly one per endpoint page, immediately after the preamble. Two permitted values.

```markdown
> **Availability:** generally available.
```

```markdown
> **Availability:** limited. This endpoint is being rolled out progressively. If it returns `404` for your account, it is not yet enabled — contact your Appning representative to request access.
```

**Default for every Console endpoint page in Phases 4–6: limited.** Never name a flag, an environment variable or an environment (ADR-005).

---

## 4. Provenance markers (ADR-002)

Appended to a field bullet, an enum value or an enforcement-table row.

| Marker | Renders as | Use when |
|---|---|---|
| *(none)* | — | Google's field **and** Google's rule. The default; keeps pages uncluttered |
| Appning | `**(Appning)**` | our field or our rule; Google publishes nothing here |
| Appning, stricter | `**(Appning — stricter than Google)**` | Google's field, our tighter rule. Never present as parity |
| Accepted, not enforced | `**(accepted, not enforced)**` | accepted and stored, but nothing acts on it — must not be used as a control |

**Punctuation:** when a marker appears inline in a field bullet, no trailing period inside the parentheses (`**(Appning)**`). When it opens a standalone paragraph, capitalise and close with a period inside (`**(Appning.)**`, `**(Accepted, not enforced.)**`). Both forms are in use and both are correct in their position.

**An unmarked field asserts "this is Google's rule."** Silence is a claim, so a forgotten marker produces a *wrong* page, not an incomplete one. This is why provenance is a required ledger column: an omission shows up as an empty cell.

Example bullets:

```markdown
- `offerTags[]` (`OfferTag`, optional): up to 20 tags after duplicates are removed.
- `offers[]` (`OneTimeProductOffer`, optional): up to 100 per purchase option. **(Appning)**
- `multiQuantityEnabled` (`boolean`, optional): **(accepted, not enforced)** stored and returned, but the charged amount is not multiplied and no quantity is recorded. Do not present a quantity selector on the strength of this flag.
```

---

## 5. Enforcement table

One per method page that enforces caps.

```markdown
| Limit | Value | Applies to | Whose rule | Enforced |
|---|---|---|---|---|
| Batch size | 100 | `requests[]` | Google | request boundary |
| Purchase options | 100 | `purchaseOptions[]` per product | **Appning** | write time |
```

`Enforced` values, and nothing else: `request boundary`, `write time`, `purchase time`, `not enforced`.

---

## 6. Error catalogue

One per endpoint page, after the response body.

```markdown
## Errors

| HTTP | `code` | When | What to change |
|---|---|---|---|
| 409 | `Conflict` — `INVALID_STATE_TRANSITION` | the target state is not reachable from the current one | read the current `state` first; see [`types/offer-state.md`](../types/offer-state.md) |
```

Conflict strings are published **verbatim** — callers match on them: `INVALID_STATE_TRANSITION`, `LAST_OFFER_OF_ACTIVE_OPTION`, `PURCHASE_OPTION_NOT_DELETABLE`, `AMBIGUOUS_LEGACY_OPTION`.

---

## 7. JSON block style (existing repo convention — do not change)

Placeholders, not examples: `"string"`, `0`, `false`, `{ "object": "TypeName" }`, `[{ "object": "TypeName" }]`.

Field bullets read: `` `name` `` + `` (`type`, required | optional | immutable | output only) `` + `:` + one line. Constraints become sub-bullets.

---

## 8. Prohibited in published pages (ADR-005 / NFR-03 / NFR-11)

File paths and `.php` names · class, service, DTO or table names · line numbers · `ADR-nnnn` · flag names and environment variables · branch names, commit hashes, PR numbers · environment names in a deploy sense · latency, throughput or percentile figures that Google does not publish.

**Permitted, because they are the wire contract:** JSON field names, enum values, error `code` strings, HTTP statuses, URL paths, header names.

`sh scripts/check-leakage.sh` enforces this. Run it every phase.

---

## 9. Wording rules fixed once (NFR-09)

- "purchase option", never bare "option", in a definition.
- "one-time product", never "product", on first use in a section.
- `relativeDiscount` is **"a fraction, not a percentage"** — this exact phrasing, every time it appears.
- `redemptionLimit` is **"a merchandising control, not a security control"** — this exact phrasing.
- Writes are **"replace, not merge"** — this exact phrasing.
- Where the service does not enforce something a client must do, the sentence says **"your client must"**, not "should".
