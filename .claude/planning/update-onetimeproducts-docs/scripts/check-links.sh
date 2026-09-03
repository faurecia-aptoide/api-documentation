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
# Warn on a "See `something`" that is code-formatted but not a link. This is the
# shape a deferred forward reference leaves behind when the link is never
# restored — invisible to the check above, because it is not link syntax at all.
unlinked=$(grep -rnE 'See `[a-zA-Z0-9_.-]+`( for| in|,|\.)' docs README.md 2>/dev/null || true)
if [ -n "$unlinked" ]; then
  echo "$unlinked"
  echo "WARN: code-formatted reference(s) after \"See\" that are not links — should these be links?"
fi

echo "PASS: all relative links resolve"
exit 0
