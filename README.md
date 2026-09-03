# Appning API

The **Appning API** enables developers to **interact with Appning services** from their own systems (server-to-server).

All endpoints are authenticated using **JWT Bearer tokens** signed locally with **RS256**.

---

## Authentication (JWT Bearer)

### Obtain API access credentials

To obtain API access credentials, go to the Developer Portal:

- https://developers.appning.com/backoffice/settings/api-access-credentials

From there, you can download a credentials file (e.g., `serviceAccount.json`) with this structure:

```json
{
  "kid": "the-key-id",
  "privateKeyPem": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "clientId": "the-client-id"
}
```

- `privateKeyPem` is **private** and must remain local (**never** sent to the server).
- `kid` identifies the key used to sign the JWT.
- `clientId` identifies the client and must be used as the value for the JWT **`iss`** and **`sub`** claims.

### JWT requirements

#### Required claims (`iss` / `sub`)

The JWT **must** include:

- `iss`: must be equal to the client’s **`clientId`**
- `sub`: must be equal to the client’s **`clientId`**

#### Token validity (policy)

The server **only accepts tokens with a maximum validity of 15 minutes**:

- The JWT **must** include `iat` and `exp` (Unix epoch seconds).
- The server validates:
  - `exp` has not expired
  - `iat` is not “in the future” (with clock skew tolerance)
  - **`exp - iat <= 900`** seconds (15 minutes)

> A clock skew tolerance of ~60 seconds on the server is recommended to account for time differences between machines.

---

## Available endpoints

Below is a list of currently documented endpoints. Additional endpoints may exist depending on the services enabled for your account.

| Service | Method | Endpoint | Description | Documentation                                                                                                                                                                                                                       
|---|---|---|---|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| AndroidPublisher | POST | `/androidpublisher/v3/applications/{packageName}/oneTimeProducts:batchUpdate` | Batch create/update one-time products (monetization) | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/batchUpdate.md">android-publisher/monetization.onetimeproducts/batchUpdate.md</a> |
| AndroidPublisher | GET | `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers` | List the offers of a purchase option | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/offers/list.md">android-publisher/monetization.onetimeproducts/offers/list.md</a> |
| AndroidPublisher | POST | `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchGet` | Read named offers | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/offers/batchGet.md">android-publisher/monetization.onetimeproducts/offers/batchGet.md</a> |
| AndroidPublisher | POST | `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers/{offerId}:activate` | Activate one offer | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/offers/activate.md">android-publisher/monetization.onetimeproducts/offers/activate.md</a> |
| AndroidPublisher | POST | `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers/{offerId}:deactivate` | Deactivate one offer | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/offers/deactivate.md">android-publisher/monetization.onetimeproducts/offers/deactivate.md</a> |
| AndroidPublisher | POST | `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchUpdateStates` | Change the state of several offers | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/offers/batchUpdateStates.md">android-publisher/monetization.onetimeproducts/offers/batchUpdateStates.md</a> |
| AndroidPublisher | POST | `/sellers/{uid}/inapp/oneTimeProducts/{productId}/purchaseOptions/{purchaseOptionId}/offers:batchDelete` | Delete offers permanently | <a href="https://github.com/faurecia-aptoide/api-documentation/blob/main/docs/appning/android-publisher/monetization.onetimeproducts/offers/batchDelete.md">android-publisher/monetization.onetimeproducts/offers/batchDelete.md</a> |

---

## Endpoint example (Bash)

The following script loads `serviceAccount.json`, generates a JWT, and calls the endpoint with `curl`. Use it to quickly test the API from your local machine.

Run by passing your own service account and package name as arguments:

```bash
sh test-endpoint.sh ./serviceAccount-<kid>.json com.your.package
```

**Requirements:** `jq`, `openssl`, `curl`

<details>
<summary>View script - <a href="./test-endpoint.sh">test-endpoint.sh</a></summary>

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Usage / argument validation ---
usage() {
  cat >&2 <<'EOF'
Usage:
  ./test-endpoint.sh <SERVICE_ACCOUNT_JSON> <PACKAGE_NAME>

Example:
  ./test-endpoint.sh ./serviceAccount-687e1dd7-957c-4728-aa5f-940894daeee5.json com.monetization.batchupdate.android
EOF
  exit 2
}

# Accept only the correct/complete arguments: exactly 2
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
fi

if [[ "$#" -ne 2 ]]; then
  echo "❌ Error: expected exactly 2 arguments, got $#" >&2
  usage
fi

SERVICE_ACCOUNT="$1"
PACKAGE_NAME="$2"

# Validate service account file
if [[ ! -f "$SERVICE_ACCOUNT" ]]; then
  echo "❌ Error: service account file not found: $SERVICE_ACCOUNT" >&2
  exit 2
fi

# Validate package name (basic Android package pattern)
if ! [[ "$PACKAGE_NAME" =~ ^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$ ]]; then
  echo "❌ Error: invalid PACKAGE_NAME: $PACKAGE_NAME" >&2
  echo "   Expected something like: com.example.app" >&2
  exit 2
fi

# --- Config ---
BASE_URL="https://product.faa.faurecia-aptoide.com/api/8.20240517"
ENDPOINT="${BASE_URL}/androidpublisher/v3/applications/${PACKAGE_NAME}/oneTimeProducts:batchUpdate"

# --- Helpers ---
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

redact() {
  # Redact tokens from curl output and errors
  sed -E \
    -e 's/([Aa]uthorization: Bearer) .*/\1 [REDACTED]/' \
    -e 's/(Bearer )[A-Za-z0-9._-]+/\1[REDACTED]/g'
}

need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Missing dependency: $1" >&2; exit 1; }; }
need jq
need openssl
need curl

# Validate JSON structure and required keys
if ! jq -e . "$SERVICE_ACCOUNT" >/dev/null 2>&1; then
  echo "❌ Error: SERVICE_ACCOUNT is not valid JSON: $SERVICE_ACCOUNT" >&2
  exit 2
fi

for key in kid clientId privateKeyPem; do
  if ! jq -e --arg k "$key" 'has($k) and (.[$k] | type=="string") and (.[$k] | length>0)' "$SERVICE_ACCOUNT" >/dev/null; then
    echo "❌ Error: SERVICE_ACCOUNT is missing/invalid key: $key" >&2
    exit 2
  fi
done

echo "=== Config ==="
echo "BASE_URL:      ${BASE_URL}"
echo "PACKAGE_NAME:  ${PACKAGE_NAME}"
echo "ENDPOINT:      ${ENDPOINT}"
echo

# --- 1) Generate JWT (RS256) ---
KID="$(jq -r '.kid' "$SERVICE_ACCOUNT")"
CLIENT_ID="$(jq -r '.clientId' "$SERVICE_ACCOUNT")"
PRIV_KEY_PEM="$(jq -r '.privateKeyPem' "$SERVICE_ACCOUNT")"

PRIV_KEY_FILE="$(mktemp)"
cleanup() { rm -f "$PRIV_KEY_FILE"; }
trap cleanup EXIT
printf '%s\n' "$PRIV_KEY_PEM" > "$PRIV_KEY_FILE"

HEADER_JSON="$(jq -cn --arg kid "$KID" '{alg:"RS256",typ:"JWT",kid:$kid}')"

NOW="$(date +%s)"
EXP="$((NOW + 900))"
JWT_PAYLOAD_JSON="$(jq -cn \
  --arg iss "$CLIENT_ID" --arg sub "$CLIENT_ID" \
  --argjson iat "$NOW" --argjson exp "$EXP" \
  '{iss:$iss,sub:$sub,iat:$iat,exp:$exp}'
)"

HEADER_B64="$(printf '%s' "$HEADER_JSON" | b64url)"
PAYLOAD_B64="$(printf '%s' "$JWT_PAYLOAD_JSON" | b64url)"
SIGNING_INPUT="${HEADER_B64}.${PAYLOAD_B64}"

SIGNATURE_B64="$(
  printf '%s' "$SIGNING_INPUT" \
  | openssl dgst -sha256 -sign "$PRIV_KEY_FILE" \
  | b64url
)"

TOKEN="${SIGNING_INPUT}.${SIGNATURE_B64}"

echo "=== JWT ==="
echo "kid: ${KID}"
echo "clientId: ${CLIENT_ID}"
echo "iat: ${NOW}"
echo "exp: ${EXP}"
echo "(Bearer token redacted in curl logs)"
echo

# --- 2) Build request body (JSON) ---
PRODUCT_ID="coin_pack_etc_$(date +%s)"

REQUEST_BODY="$(jq -cn --arg packageName "$PACKAGE_NAME" --arg productId "$PRODUCT_ID" '
{
  requests: [
    {
      oneTimeProduct: {
        packageName: $packageName,
        productId: $productId,
        listings: [
          { languageCode: "fr-FR", title: "test fr 300 Pièces", description: "Recevez 300 pièces instantanément" },
          { languageCode: "en-US", title: "test en 300 Coins",  description: "Receive 300 coins instantly" }
        ],
        purchaseOptions: [
          {
            purchaseOptionId: "default",
            buyOption: {
              legacyCompatible: true,
              multiQuantityEnabled: false
            },
            regionalPricingAndAvailabilityConfigs: [
              {
                regionCode: "FR",
                price: { currencyCode: "EUR", units: "1", nanos: 880000000 },
                availability: "AVAILABLE"
              },
              {
                regionCode: "US",
                price: { currencyCode: "USD", units: "2", nanos: 980000000 },
                availability: "AVAILABLE"
              }
            ]
          }
        ],
        regionsVersion: { version: "2025/03" }
      },
      updateMask: "listings,purchaseOptions",
      allowMissing: true,
      latencyTolerance: "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT",
      regionsVersion: { version: "2025/03" }
    }
  ]
}
')"

echo "=== Request ==="
echo "PRODUCT_ID: ${PRODUCT_ID}"
echo "POST ${ENDPOINT}"
echo "Headers:"
echo "  Authorization: Bearer [REDACTED]"
echo "  Content-Type: application/json"
echo
echo "--- Request Body (pretty) ---"
echo "$REQUEST_BODY" | jq .
echo "-----------------------------"
echo

# --- 3) Call endpoint (terminal logs only, no files) ---
echo "=== Response ==="

exec 3>&1
set +e
curl --fail-with-body -sS \
  -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary "$REQUEST_BODY" \
  -w $'\n\n=== CURL METRICS ===\nHTTP_STATUS: %{http_code}\nTOTAL_TIME: %{time_total}s\n=== END ===\n' \
  2>&1 1>&3 | redact >&2
CURL_RC=${PIPESTATUS[0]}
set -e
exec 3>&-

echo
echo "curl exit code: ${CURL_RC}"
if [[ "$CURL_RC" -ne 0 ]]; then
  echo "❌ Request failed (curl rc=${CURL_RC}). Check the response body/headers above for routing or API details." >&2
  exit "$CURL_RC"
fi

echo "✅ Done"
```

</details>

---

## Responses

### 200 OK

Request processed successfully.

```json
[
  {
    "oneTimeProduct": {
      "packageName": "payments.qa.test18",
      "productId": "coin_pack_etc_1772464980",
      "listings": [
        {
          "languageCode": "fr-FR",
          "title": "test fr 300 Pièces",
          "description": "Recevez 300 pièces instantanément"
        },
        {
          "languageCode": "en-US",
          "title": "test en 300 Coins",
          "description": "Receive 300 coins instantly"
        }
      ],
      "purchaseOptions": [
        {
          "purchaseOptionId": "default",
          "buyOption": {
            "legacyCompatible": true,
            "multiQuantityEnabled": false
          },
          "regionalPricingAndAvailabilityConfigs": [
            {
              "regionCode": "FR",
              "price": {
                "currencyCode": "EUR",
                "units": 1,
                "nanos": 880000000
              },
              "availability": "AVAILABLE"
            },
            {
              "regionCode": "US",
              "price": {
                "currencyCode": "USD",
                "units": 2,
                "nanos": 980000000
              },
              "availability": "AVAILABLE"
            }
          ]
        }
      ],
      "regionsVersion": {
        "version": "2025/03"
      }
    },
    "updateMask": "listings,purchaseOptions",
    "allowMissing": true,
    "latencyTolerance": "PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT",
    "regionsVersion": {
      "version": "2025/03"
    }
  }
]
```

### 400 Bad Request

Invalid payload / validation failure.

```json
{
  "error":{
    "code":400,
    "message":"An invalid value was given in the following body field: \\u201cbody\\u201d, with the following error: invalid request body.",
    "errors":[
      {
        "message":{
          "enduser":"Invalid request body.",
          "technical":"Invalid request body."
        },
        "domain":"global",
        "reason":"badRequest",
        "location":"body"
      }
    ],
    "status":"INVALID_ARGUMENT"
  }
}
```

Typical causes:
- missing required fields
- invalid types/formats
- business rules not met

### 401 Unauthorized

Authentication failure / invalid token.

```json
{
  "error":{
    "code":401,
    "message":"The given authentication credentials, to access the targeted resource, are invalid.",
    "errors":[
      {
        "message":"The given authentication credentials, to access the targeted resource, are invalid.",
        "domain":"global",
        "reason":"required"
      }
    ],
    "status":"UNAUTHENTICATED"
  }
}
```

Typical causes:
- missing or malformed `Authorization` header
- malformed JWT
- invalid signature
- unknown or revoked `kid`
- expired token (`exp`)
- token validity greater than 15 minutes (**`exp - iat > 900`**)
- `iat` too far in the future (outside clock-skew tolerance)
- missing `iss` / `sub`
- `iss` not equal to `clientId`
- `sub` not equal to `clientId`

### 403 Forbidden

Token is valid, but the caller lacks permission to perform this operation.

```json
{
  "error":{
    "code":403,
    "message":"Access to the targeted resource is forbidden.",
    "errors":[
      {
        "message":"Access to the targeted resource is forbidden.",
        "domain":"global",
        "reason":"accessNotConfigured"
      }
    ],
    "status":"PERMISSION_DENIED"
  }
}
```

Typical causes:
- the client identified by `iss/sub` is not authorized for this endpoint
- the endpoint requires a different access level

### 404 Not Found

The resource was not found

```json
{
  "error":{
    "code":404,
    "message":"The targeted resource was not found.",
    "errors":[
      {
        "message":"The targeted resource was not found.",
        "domain":"global",
        "reason":"notFound"
      }
    ],
    "status":"NOT_FOUND"
  }
}
```
Typical causes:
- the package is not available to receive monetization products
- the package does not exist under the supplied service account credentials

---

## Troubleshooting

- **400**
  - validate the request body against the endpoint’s expected schema
- **401: invalid signature**
  - confirm `kid` matches the public key registered for your credentials
  - confirm the private key used to sign matches the server-side public key
- **401: invalid issuer/subject**
  - confirm `iss` and `sub` are present and both equal to the `clientId` from `serviceAccount.json`
- **401: expired token / TTL**
  - confirm `iat`/`exp` are Unix seconds
  - confirm `exp - iat <= 900`
  - ensure system clock is correct (NTP) and server clock-skew tolerance is set
- **403**
  - confirm the permissions associated with your `clientId`
- **404**
  - confirm the package name settings via https://developers.appning.com
