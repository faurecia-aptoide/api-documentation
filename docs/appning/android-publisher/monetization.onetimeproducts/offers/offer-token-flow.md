# Using `offer_token`

Appning extension. Google publishes no equivalent flow.

How a client tells Appning which offer a buyer chose. For the token's format and properties, see [`../types/offer-token.md`](../types/offer-token.md).

> **Status.** Everything in "What is true today" is live and observable now. The purchase-time contract in "Sending the token with a purchase" is **defined and implemented on the receiving side, but no shipped payment broker forwards the token yet** — so sending it has no effect today. It is documented now so that an integration built against it is correct when forwarding arrives.

## What is true today

Every offer returned by the one-time products catalogue, and by a seller's product detail read, carries an `offer_token`. It is derived on every read, so it is always present and always current.

The token names one offer, on one purchase option, of one product. It carries **no price** and grants **no permission**.

## Sending the token with a purchase

A purchase request accepts `offer_token` as a top-level field:

```json
{
  "offer_token": "otk_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
}
```

- Optional, and at most 64 characters.
- An unrecognised token does **not** fail the purchase. It is recorded as "no offer identified" and the purchase proceeds. This is deliberate: a buyer's card must never be charged and then left without an entitlement because of this field.
- When the token does resolve, the purchase records which purchase option and offer it was made against.

### The per-buyer redemption limit

An offer may set `redemptionLimit`. When a resolved token points at an offer whose limit the buyer has already reached, the purchase is refused with `403`.

- `0` means unlimited. Otherwise the value is `1` to `50`.
- The range is checked when the offer is written. The count is enforced at purchase time.
- A purchase stops counting towards the limit if it is refunded, charged back or cancelled.
- **It is a merchandising control, not a security control.** A caller that sends no `offer_token` is not counted at all, so do not rely on it to enforce entitlement scarcity.
- The catalogue keeps returning an offer whose limit a buyer has reached. The refusal happens at purchase time, not at read time.

## Rules for resolving a price

If you resolve a token yourself — for example in a payment broker that must confirm what to charge — these rules are not optional. Each one has a failure mode that is expensive and quiet.

1. **Re-read the catalogue.** Fetch the product from the one-time products catalogue and match the token against the offers you get back, by exact string comparison. There is **no** endpoint that exchanges a token for an offer, and none is planned.
2. **Read `price.value` with `price.currency`. Never read `price.micros`.** Scales differ between services, and reading the wrong one mis-charges by a factor of 100.
3. **Parse `price.value` as a decimal.** Trailing zeros are trimmed, so five units is `"5"`, not `"5.00"`. Do not assume two decimal places.
4. **Do not cache.** Not the catalogue response, not a resolved token. Read once per transaction. The token carries no expiry, and freshness of the read is what expires it: an offer that has ended, or that is no longer active, is simply absent from the response.
5. **Fail closed.** If the token does not resolve, refuse the purchase. Never fall back to a price supplied by the client, because the client controls it.
6. **Show one message.** "This offer has ended" and "this token is not valid" are indistinguishable by design — in both cases the token is simply absent from the response. Tell the buyer the offer is not available, and nothing more precise.

## What the token is not

- **Not a signed price.** It carries no amount. Trust comes from re-reading the catalogue, which is the price authority — not from the token itself.
- **Not an authorisation.** It grants nothing and proves nothing about the buyer.
- **Not reversible.** You cannot decode it, and you cannot construct one for an offer you have not read.

## Local references

- [`../types/offer-token.md`](../types/offer-token.md)
- [`offers.md`](./offers.md)
- [`../types/resolved-price.md`](../types/resolved-price.md)
- [`../monetization.onetimeproducts.md`](../monetization.onetimeproducts.md)
