# Schema: `offer_token`

Appning extension. Google publishes no equivalent field.

An opaque string naming one offer, on one purchase option, of one one-time product. It is returned with every offer on the catalogue reads and is the value a purchase request carries to say which offer the buyer chose. **(Appning)**

## JSON

```json
{
  "offer_token": "otk_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}
```

## Format

- Prefix `otk_`, followed by 32 base64url characters — 36 characters in total.
- Character set after the prefix: `A`–`Z`, `a`–`z`, `0`–`9`, `-` and `_`.
- Treat it as opaque. Do not parse it, split it, or derive anything from its content.

## Properties

- **Not reversible.** The token is a one-way digest of the product, purchase option and offer identifiers. It cannot be decoded back into them, and there is no endpoint that exchanges a token for an offer.
- **Stable.** The same offer yields the same token on every read, so a token received earlier can be matched against a later catalogue response by string comparison.
- **No expiry inside the token.** Nothing in it says when the offer ends. Freshness comes from re-reading the catalogue: an offer that has ended, or that is no longer active, is simply absent from the response.
- **It names an offer. It is not a signed price and it is not an authorisation.** It carries no amount and grants no permission.

## Where it appears

| Read | Carries `offer_token` |
|---|---|
| the one-time products catalogue, per offer | yes |
| a seller's one-time product detail, per offer | yes |
| a seller's offers list, and `offers:batchGet` | **no** |
| purchase history | no |

## Using it

See [`offer-token-flow.md`](../offers/offer-token-flow.md) for what a client does with the token, including the rules for reading a price correctly.

## Local references

- [`resolved-price.md`](./resolved-price.md)
- [`../offers/offers.md`](../offers/offers.md)
- [`../offers/offer-token-flow.md`](../offers/offer-token-flow.md)
