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

## JWT generation (Bash snippet)

You can reuse the following snippet to generate a JWT token from `serviceAccount.json`.

**Requirements:** `jq`, `openssl`

```bash
# Inputs
SERVICE_ACCOUNT="./serviceAccount.json"

# Read kid + private key + clientId from the local JSON file
KID="$(jq -r '.kid' "$SERVICE_ACCOUNT")"
CLIENT_ID="$(jq -r '.clientId' "$SERVICE_ACCOUNT")"
PRIV_KEY_PEM="$(jq -r '.privateKeyPem' "$SERVICE_ACCOUNT")"

# Write PEM to a temporary file (openssl works best with a file)
PRIV_KEY_FILE="$(mktemp)"
cleanup() { rm -f "$PRIV_KEY_FILE"; }
trap cleanup EXIT
printf '%s\n' "$PRIV_KEY_PEM" > "$PRIV_KEY_FILE"

# JWT header
HEADER_JSON="$(jq -cn --arg kid "$KID" '{alg:"RS256",typ:"JWT",kid:$kid}')"

# JWT payload (max TTL 15 min) + required iss/sub = clientId
NOW="$(date +%s)"
EXP="$((NOW + 900))" # 900s = 15 min
PAYLOAD_JSON="$(jq -cn \
  --arg iss "$CLIENT_ID" --arg sub "$CLIENT_ID" \
  --argjson iat "$NOW" --argjson exp "$EXP" \
  '{iss:$iss,sub:$sub,iat:$iat,exp:$exp}'
)"

# base64url helper (no padding)
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

HEADER_B64="$(printf '%s' "$HEADER_JSON" | b64url)"
PAYLOAD_B64="$(printf '%s' "$PAYLOAD_JSON" | b64url)"
SIGNING_INPUT="${HEADER_B64}.${PAYLOAD_B64}"

SIGNATURE_B64="$(
  printf '%s' "$SIGNING_INPUT" \
  | openssl dgst -sha256 -sign "$PRIV_KEY_FILE" \
  | b64url
)"

TOKEN="${SIGNING_INPUT}.${SIGNATURE_B64}"
echo "$TOKEN"
```

---

## Available endpoints

Below is a list of currently documented endpoints. Additional endpoints may exist depending on the services enabled for your account.

| Service | Method | Endpoint | Description | Documentation
|---|---|---|---|-|
| AndroidPublisher | POST | `/androidpublisher/v3/applications/{packageName}/oneTimeProducts:batchUpdate` | Batch create/update one-time products (monetization) | https://developers.google.com/android-publisher/api-ref/rest/v3/monetization.onetimeproducts/batchUpdate|

---

## Endpoint example (Bash)

### AndroidPublisher - oneTimeProducts:batchUpdate

**Method:** `POST`  
**Path:** `/androidpublisher/v3/applications/{packageName}/oneTimeProducts:batchUpdate`  
**Auth:** `Authorization: Bearer <token>`  
**Content-Type:** `application/json`
#### Example request (equivalent to the sample shown)

This example:
- loads `serviceAccount.json`
- creates a JWT
- builds a request body similar to the provided sample (with a timestamped `productId`)
- calls the endpoint with `curl`

**Requirements:** `jq`, `openssl`, `curl`

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- Config ---
BASE_URL="https://product.faa.faurecia-aptoide.com"
SERVICE_ACCOUNT="./serviceAccount.json"

PACKAGE_NAME="com.example.app"
ENDPOINT="${BASE_URL}/androidpublisher/v3/applications/${PACKAGE_NAME}/oneTimeProducts:batchUpdate"

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

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }

HEADER_B64="$(printf '%s' "$HEADER_JSON" | b64url)"
PAYLOAD_B64="$(printf '%s' "$JWT_PAYLOAD_JSON" | b64url)"
SIGNING_INPUT="${HEADER_B64}.${PAYLOAD_B64}"

SIGNATURE_B64="$(
  printf '%s' "$SIGNING_INPUT" \
  | openssl dgst -sha256 -sign "$PRIV_KEY_FILE" \
  | b64url
)"

TOKEN="${SIGNING_INPUT}.${SIGNATURE_B64}"

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
          { languageCode: "pt-BR", title: "300 Moedas", description: "Receba 300 moedas instantaneamente" },
          { languageCode: "en-US", title: "300 Coins",  description: "Receive 300 coins instantly" }
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
                regionCode: "US",
                price: { currencyCode: "USD", units: "1", nanos: 880000000 },
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


# --- 3) Call endpoint ---
echo "Calling batchUpdate for package: ${PACKAGE_NAME}"
curl -sS -X POST "$ENDPOINT" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "$REQUEST_BODY"

echo
echo "✅ Done"
```

---

## Responses

### 200 OK

Request processed successfully.

```json
[
  {
    "oneTimeProduct":{
      "packageName":"com.example.android",
      "productId":"coin_pack_200_11771861403",
      "listings":[
        {
          "languageCode":"pt-BR",
          "title":"300 Moedas",
          "description":"Receba 100 moedas instantaneamente"
        },
        {
          "languageCode":"en-US",
          "title":"300 Coins",
          "description":"Receive 100 coins instantly"
        }
      ],
      "purchaseOptions":[
        {
          "purchaseOptionId":"default",
          "buyOption":{
            "legacyCompatible":true,
            "multiQuantityEnabled":false
          },
          "regionalPricingAndAvailabilityConfigs":[
            {
              "regionCode":"US",
              "price":{
                "currencyCode":"USD",
                "units":"1",
                "nanos":880000000
              },
              "availability":"UNAVAILABLE"
            },
            {
              "regionCode":"BR",
              "price":{
                "currencyCode":"BRL",
                "units":"3",
                "nanos":870000000
              },
              "availability":"UNAVAILABLE"
            },
            {
              "regionCode":"MX",
              "price":{
                "currencyCode":"MXN",
                "units":"2",
                "nanos":860000000
              },
              "availability":"UNAVAILABLE"
            }
          ]
        }
      ],
      "regionsVersion":{
        "version":"2025\\/03"
      }
    },
    "updateMask":"listings,purchaseOptions",
    "allowMissing":true,
    "latencyTolerance":"PRODUCT_UPDATE_LATENCY_TOLERANCE_LATENCY_TOLERANT",
    "regionsVersion":{
      "version":"2025\\/03"
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
