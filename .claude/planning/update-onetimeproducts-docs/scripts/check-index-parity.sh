#!/usr/bin/env bash
# Asserts the file tree matches the two hand-maintained indexes (NFR-05, TR-15).
#  a) every .md under monetization.onetimeproducts/ (except a README) is named
#     in that group's README.md
#  b) every endpoint page is named in the root README.md endpoint table
set -u
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT" || exit 2
GROUP="docs/appning/android-publisher/monetization.onetimeproducts"
INDEX="$GROUP/README.md"
fail=0

[ -f "$INDEX" ] || { echo "FAIL: missing $INDEX"; exit 1; }

for f in $(find "$GROUP" -name '*.md' | sort); do
  base=$(basename "$f")
  [ "$base" = "README.md" ] && continue
  if ! grep -q "$base" "$INDEX"; then
    echo "MISSING FROM SECTION INDEX  $f"
    fail=1
  fi
done

for f in $(find "$GROUP/offers" "$GROUP/purchase-options" -name '*.md' 2>/dev/null | sort) "$GROUP/batchUpdate.md"; do
  [ -f "$f" ] || continue
  base=$(basename "$f")
  [ "$base" = "README.md" ] && continue
  if ! grep -q "$base" README.md; then
    echo "MISSING FROM ROOT ENDPOINT TABLE  $f"
    fail=1
  fi
done

[ "$fail" -eq 0 ] && { echo "PASS: indexes match the file tree"; exit 0; }
echo "FAIL: index drift above"
exit 1
