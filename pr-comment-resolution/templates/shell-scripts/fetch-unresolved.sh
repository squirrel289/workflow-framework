#!/bin/bash
# Fetch all unresolved threads from a PR
# Output: JSON file with thread details

set -euo pipefail

OWNER="${1:-}"
REPO="${2:-}"
PR_NUMBER="${3:-}"

if [ -z "$OWNER" ] || [ -z "$REPO" ] || [ -z "$PR_NUMBER" ]; then
    echo "Usage: $0 <OWNER> <REPO> <PR_NUMBER>"
    echo ""
    echo "Example: $0 squirrel289 temple 42"
    exit 1
fi

OUTPUT_FILE="${4:-unresolved_threads.json}"

echo "Fetching unresolved threads from $OWNER/$REPO PR #$PR_NUMBER..."

gh pr-review review view -R "$OWNER/$REPO" --pr "$PR_NUMBER" \
    --unresolved --not_outdated > "$OUTPUT_FILE"

THREAD_COUNT=$(jq '[.reviews[].comments[]] | length' "$OUTPUT_FILE")

echo "Found $THREAD_COUNT unresolved thread(s)"
echo "Output saved to: $OUTPUT_FILE"

# Pretty print summary
if [ "$THREAD_COUNT" -gt 0 ]; then
    echo ""
    echo "Threads:"
    jq -r '.reviews[].comments[] | "  [\(.thread_id)] \(.path):\(.line // "?") - \(.body | .[0:80])..."' "$OUTPUT_FILE"
fi
