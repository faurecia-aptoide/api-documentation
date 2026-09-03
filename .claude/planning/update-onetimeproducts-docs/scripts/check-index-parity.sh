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

# An endpoint page is one that documents an HTTP request. Resource, type and
# index pages are not endpoints and do not belong in the endpoint table.
for f in $(find "$GROUP" -name '*.md' | sort); do
  [ -f "$f" ] || continue
  grep -q '^## HTTP request' "$f" || continue
  base=$(basename "$f")
  if ! grep -q "$base" README.md; then
    echo "MISSING FROM ROOT ENDPOINT TABLE  $f"
    fail=1
  fi
done

[ "$fail" -eq 0 ] && { echo "PASS: indexes match the file tree"; exit 0; }
echo "FAIL: index drift above"
exit 1
