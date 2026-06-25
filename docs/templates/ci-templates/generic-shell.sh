#!/bin/sh
# Generic shell hook for Drone, Jenkins, Buildkite, or any POSIX CI.
# Run after checkout with BEFORE_SHA and AFTER_SHA pointing at the range to diff.
#
# Required env vars (set before running this script):
#   BEFORE_SHA                       — git SHA of the previous commit
#   AFTER_SHA                        — git SHA of the current commit
#   NOTION_API_KEY
#   GOOGLE_SA_KEY                    (base64-encoded service-account JSON)
#   MICROSOFT_OAUTH_CLIENT_ID
#   MICROSOFT_OAUTH_TENANT_ID
#   MICROSOFT_OAUTH_REFRESH_TOKEN

set -euo pipefail

# Write Google service-account key
printf '%s' "$GOOGLE_SA_KEY" | base64 -d > /tmp/google-sa.json
chmod 600 /tmp/google-sa.json
export GOOGLE_SERVICE_ACCOUNT_KEY_PATH=/tmp/google-sa.json

# Compute changed files relevant to doc sync
CHANGED=$(git diff --name-only "${BEFORE_SHA}" "${AFTER_SHA}" \
  | grep -E '^customer-docs/.+/(roadmap\.csv|plans/.+\.md)$' \
  | tr '\n' ',' | sed 's/,$//')

if [ -z "$CHANGED" ]; then
  echo "No customer doc changes detected — skipping sync."
  exit 0
fi

echo "Changed files: $CHANGED"

bun install --frozen-lockfile --ignore-scripts
bun run sync-customer-docs \
  --changed-files "$CHANGED"
