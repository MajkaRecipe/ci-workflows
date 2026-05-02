#!/bin/bash
set -e

# ── Configuration ─────────────────────────────────────
SINCE_TAG="${1:-v0.0.0}"

# ── Scan commits since given tag ──────────────────────
if [ "$SINCE_TAG" = "v0.0.0" ]; then
  COMMITS=$(git log HEAD --pretty=format:"%s|%h")
else
  COMMITS=$(git log "${SINCE_TAG}..HEAD" --pretty=format:"%s|%h")
fi

echo "Generating changelog since $SINCE_TAG"

commit_link() {
  local hash="$1"

  if [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
    echo "[${hash}](${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commit/${hash})"
  else
    echo "$hash"
  fi
}

# ── Categorize commits ────────────────────────────────
FIXES=""
FEATURES=""

while IFS='|' read -r msg hash; do
  [ -z "$msg" ] && continue

  if echo "$msg" | grep -qE "^fix(\(.+\))?:"; then
    SCOPE=$(echo "$msg" | grep -oP "(?<=fix\().*(?=\))" || true)
    DESC=$(echo "$msg" | sed 's/^fix([^)]*): //;s/^fix: //')
    LINK=$(commit_link "$hash")
    if [ -n "$SCOPE" ]; then
      FIXES="${FIXES}\n* ${SCOPE}: ${DESC} (${LINK})"
    else
      FIXES="${FIXES}\n* ${DESC} (${LINK})"
    fi

  elif echo "$msg" | grep -qE "^feat(\(.+\))?:"; then
    SCOPE=$(echo "$msg" | grep -oP "(?<=feat\().*(?=\))" || true)
    DESC=$(echo "$msg" | sed 's/^feat([^)]*): //;s/^feat: //')
    LINK=$(commit_link "$hash")
    if [ -n "$SCOPE" ]; then
      FEATURES="${FEATURES}\n* ${SCOPE}: ${DESC} (${LINK})"
    else
      FEATURES="${FEATURES}\n* ${DESC} (${LINK})"
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