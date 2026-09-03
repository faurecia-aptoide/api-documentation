#!/usr/bin/env bash
# Asserts every relative Markdown link under docs/ and in the root README.md
# resolves to a file that exists. Anchors are stripped; absolute URLs skipped.
# Usage: sh .claude/planning/update-onetimeproducts-docs/scripts/check-links.sh
set -u
ROOT="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$ROOT" || exit 2
fail=0
files=$(find docs -name '*.md' 2>/dev/null; echo README.md)
for f in $files; do
  [ -f "$f" ] || continue
  dir=$(dirname "$f")
  # pull the target out of every ](...) link
  grep -oE '\]\([^)]+\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | while read -r target; do
    case "$target" in
      http://*|https://*|mailto:*|'#'*) continue ;;
    esac
    clean=${target%%#*}
    [ -z "$clean" ] && continue
    if [ ! -e "$dir/$clean" ]; then
      echo "BROKEN LINK  $f  ->  $target"
      echo x >> /tmp/.linkfail.$$
    fi
  done
done
if [ -f /tmp/.linkfail.$$ ]; then
  n=$(wc -l < /tmp/.linkfail.$$ | tr -d ' ')
  rm -f /tmp/.linkfail.$$
  echo "FAIL: $n broken relative link(s)"
  exit 1
fi
echo "PASS: all relative links resolve"
exit 0
