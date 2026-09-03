# Audit: the eight `types/` pages PAY-1889 never opened

**Date:** 2026-09-03 · **Source of truth:** `web-product-service-laravel` @ `origin/staging` `c4dd77a`
**Prompted by:** the re-review finding that three certified-text defects had been found in this repository, two of them by verification passes rather than by the original audit, and the third only because a fix happened to force a file open. These eight pages had never been checked against code and had no claim-ledger entries.

## Result

**Findings in 8 of 8 pages.** Not one was clean.

For context: the audit that produced PAY-1889 examined this repository and reported **zero** divergences, describing it as "the most accurate written source in the whole audit". Including the three found earlier in this ticket, the true count is now **eleven** distinct defects across eleven pages.

| Page | Finding | Class |
|---|---|---|
| `restricted-payment-countries.md` | Documents a field this service does not implement | A |
| `tax-tier.md` | Same — product-level tax settings are not implemented | A |
| `streaming-tax-type.md` | Same | A |
| `regional-product-age-rating-info.md` | Same | A |
| `money.md` | Documents value ranges this service rejects | B |
| `product-update-latency-tolerance.md` | Lists a value this service rejects; states a default that is wrong here | C |
| `offer-tag.md` | States a constraint stricter than the one enforced | D |
| `regions-version.md` | Required, but nothing it describes is checked, stored or echoed | E |

---

## Class A — four pages document a contract this service does not implement

`restrictedPaymentCountries` and the **product-level** `taxAndComplianceSettings` block (which contains `regionalTaxConfigs` → `TaxTier`/`StreamingTaxType`, `regionalProductAgeRatingInfos`, `isTokenizedDigitalAsset`, `productTaxCategoryCode`) are both **rejected updateMask roots** (`BatchUpdateItem.php:545-548`, message at `:2722-2727`). Naming either in `updateMask` is a `400`.

More than that: `regionalTaxConfigs`, `productTaxCategoryCode`, `isTokenizedDigitalAsset` and `regionalProductAgeRatingInfos` appear **nowhere in `app/`** except a single explanatory comment. Nothing parses them, nothing stores them, no read returns them. They are tolerated in a request body so older clients do not break, and then ignored.

So four pages described field semantics, enum vocabularies and region rules in full detail, with no indication that sending any of it has no effect and that naming it in an `updateMask` fails. A reader had every reason to believe these were working controls.

**Fixed:** each page now opens with an explicit "Not implemented by this API" block stating that the field is accepted-and-ignored, that `updateMask` rejects it with `400`, and that the page documents Google's schema for recognisability only. The tax pages also point at the **purchase-option-level** `withdrawalRightType`, which is a different field and *is* implemented — a distinction that is easy to miss and was itself the subject of an in-repo warning.

## Class B — `money.md` documents ranges this service rejects

Published Google's signed `Money`: `nanos` from `-999999999` to `999999999`, with sign rules for negative `units`.

This service accepts **no negative amount**. `nanos` is constrained to `[0, 1_000_000_000)` in the DTO constructor (`Money.php:29-33`) and `units` must not be negative at the wire boundary (`BatchUpdateItem.php:847-850`); a price of exactly zero is also rejected (`:857-860`), while a *discount* of zero is legal. Google's sign rules are unreachable here.

**Fixed:** Google's range is still stated, followed by an `(Appning — stricter than Google)` marker giving the real bounds and the three error messages a caller can actually receive.

## Class C — `product-update-latency-tolerance.md`, the same defect as C2, one page over

This is the page behind the `latencyTolerance` bug corrected earlier in this ticket as **C2**. Fixing `batchUpdate.md`'s invalid example and field bullet did not follow through to the type page, which still:

- listed `PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_SENSITIVE` as an available value — **this service rejects it with `400`**;
- stated that `…UNSPECIFIED` "Defaults to `…LATENCY_SENSITIVE`" — Google's behaviour, not this service's, which treats absent and unspecified alike and does not fall through;
- presented Google's throughput figures (7,200 and 720,000 updates per app per hour) as though they characterised this API.

An incomplete fix is its own finding, and worth naming as such: C2 was reported and closed while the same false statement stayed published one file away.

**Fixed:** the page now separates "Values accepted by this API" (two values, with the rejection stated) from "Google's stated propagation behaviour" (the figures, explicitly labelled as Google's own and not measurements of this service, with a pointer to the `429` this API returns instead).

## Class D — `offer-tag.md` overstates the constraint

Published "Must conform to RFC-1034". The enforced rule is `^[a-z0-9-]{1,20}$`, and **a leading hyphen is deliberately accepted** even though RFC-1034 labels forbid one — the code's reasoning is that Google's normative sentence states only the character set and the length, so rejecting a leading hyphen would refuse input Google accepts (`BatchUpdateItem.php:160-172`).

Being stricter in documentation than in code is the safer direction of error, but it still misdescribes the contract, and it hid two facts worth knowing: the de-duplication behaviour (20 counted *after* duplicates are removed), and that tag content was not validated at all before 2026-08-18, so older stored tags may violate the current rule.

**Fixed:** exact pattern, exact error message, the leading-hyphen note with its reason, the three levels tags apply at, the de-duplication rule, and the pre-2026-08-18 caveat.

## Class E — `regions-version.md` describes semantics nothing enforces

`items[].regionsVersion.version` is genuinely required and must not be blank. Beyond that, **any non-empty string is accepted** — there is no check that it names a real region-set version — the write path neither stores nor echoes it, and `regionsVersion` is a forbidden `updateMask` root.

The page's description of version semantics is Google's model. None of it is verified here, and a reader could reasonably have concluded that sending an older version selects an older pricing set.

**Fixed:** Google's description retained, followed by a "What this API actually checks" section stating the required-and-non-blank rule, that the value is unvalidated, that it is not stored or echoed, and that it is immutable in `updateMask`.

---

## What this says about the process, not just the pages

1. **The original audit's "zero divergences" verdict does not hold.** Eleven defects across eleven pages, in a repository singled out as the most accurate source examined. The verdict was almost certainly reached by reading the pages for internal coherence rather than against the code — which is exactly the failure mode the pages themselves suffered from.

2. **Class A is the most serious category, and the least visible.** A page that documents a field in complete, correct Google detail *looks* finished. Nothing about it signals that the field does nothing here. Only checking whether the codebase reads the field at all surfaces it — and that check is easy to skip when the page contains no factual error about Google's schema.

3. **An incomplete fix hid in plain sight.** C2 was found, reported, fixed and reported closed while the identical false statement remained one file away, on the very page the fixed field links to. A defect's blast radius needs checking beyond the file that surfaced it.

4. **Coverage, not correctness, was the weak point throughout.** Every gate in this ticket passed at every phase. All three of this ticket's original certified-text defects, and all eight of these, were found by *reading source against a page* — never by a script. The scripts protect structure; only citation-backed reading protects facts.

## Recommendation

`04_CLAIM_LEDGER.md` now covers every page in this method group. Two things follow:

- **Treat any page without ledger rows as unverified**, not as verified-by-silence. That is the rule that would have caught all of this earlier.
- **The rest of this repository is out of scope for PAY-1889 and still unaudited** — the `docs/appning/android-publisher/` tree contains only this method group today, so the exposure is currently bounded, but the same rule should apply to any group added later.
