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