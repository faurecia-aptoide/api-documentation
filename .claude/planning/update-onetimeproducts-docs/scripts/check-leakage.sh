#!/usr/bin/env bash
# Asserts no internal identifiers appear in published pages (ADR-005, NFR-03).
# Published surface = docs/ plus the root README.md. Planning files are exempt.
set -u
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT" || exit 2
fail=0

# 1. literal internal markers
if grep -rnE '\.php|ADR-0|V8_OTP_|OFFER_TOKEN_SECRET|origin/staging|origin/main|database/migrations|app/(Dto|Http|Services|Enums|Support|Models)/' docs README.md 2>/dev/null; then
  echo "FAIL: internal identifier(s) above"
  fail=1
fi

# 2. commit-hash-shaped strings: 7-40 hex chars containing at least one a-f
#    letter. Two-stage so the API version string (8.20240517, all digits) does
#    not false-positive. BSD grep has no lookahead, hence the pipe.
#    UUIDs are blanked first: an example key id (serviceAccount-<uuid>.json) is
#    legitimate content, not a commit reference.
hits=$(for f in $(find docs -name '*.md' 2>/dev/null; echo README.md); do
    [ -f "$f" ] || continue
    sed -E 's/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/UUID/g' "$f" \
      | grep -noE '\b[0-9a-f]{7,40}\b' \
      | grep -E ':[0-9a-f]*[a-f][0-9a-f]*$' \
      | sed "s|^|$f:|"
  done || true)
if [ -n "$hits" ]; then
  echo "$hits"
  echo "FAIL: commit-hash-shaped string(s) above"
  fail=1
fi

# 3. unmeasured performance claims (NFR-11)
if grep -rnE '\bp99\b|\bp95\b|per second|[0-9]+ *ms\b' docs README.md 2>/dev/null; then
  echo "FAIL: unmeasured performance claim(s) above"
  fail=1
fi

[ "$fail" -eq 0 ] && { echo "PASS: no internal identifiers, hashes or perf claims"; exit 0; }
exit 1
