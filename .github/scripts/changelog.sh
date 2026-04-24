#!/bin/bash
set -e

# ── Configuration ─────────────────────────────────────
SINCE_TAG="${1:-v0.0.0}"

# ── Scan commits since given tag ──────────────────────
COMMITS=$(git log "${SINCE_TAG}..HEAD" --pretty=format:"%s|%h")

echo "Generating changelog since $SINCE_TAG"

# ── Categorize commits ────────────────────────────────
FIXES=""
FEATURES=""

while IFS='|' read -r msg hash; do
  [ -z "$msg" ] && continue

  if echo "$msg" | grep -qE "^fix(\(.+\))?:"; then
    SCOPE=$(echo "$msg" | grep -oP "(?<=fix\().*(?=\))" || true)
    DESC=$(echo "$msg" | sed 's/^fix([^)]*): //;s/^fix: //')
    if [ -n "$SCOPE" ]; then
      FIXES="${FIXES}\n* ${SCOPE}: ${DESC} (${hash})"
    else
      FIXES="${FIXES}\n* ${DESC} (${hash})"
    fi

  elif echo "$msg" | grep -qE "^feat(\(.+\))?:"; then
    SCOPE=$(echo "$msg" | grep -oP "(?<=feat\().*(?=\))" || true)
    DESC=$(echo "$msg" | sed 's/^feat([^)]*): //;s/^feat: //')
    if [ -n "$SCOPE" ]; then
      FEATURES="${FEATURES}\n* ${SCOPE}: ${DESC} (${hash})"
    else
      FEATURES="${FEATURES}\n* ${DESC} (${hash})"
    fi
  fi
done <<< "$COMMITS"

# ── Build changelog ───────────────────────────────────
CHANGELOG=""

if [ -n "$FIXES" ]; then
  CHANGELOG="${CHANGELOG}Bug Fixes\n${FIXES}\n\n"
fi

if [ -n "$FEATURES" ]; then
  CHANGELOG="${CHANGELOG}Features\n${FEATURES}\n"
fi

if [ -z "$CHANGELOG" ]; then
  CHANGELOG="No notable changes."
fi

echo "Changelog:"
echo -e "$CHANGELOG"

# ── Write changelog to file ───────────────────────────
echo -e "$CHANGELOG" > /tmp/changelog.txt
echo "changelog_file=/tmp/changelog.txt" >> "$GITHUB_OUTPUT"