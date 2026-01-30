#!/bin/bash
# Resolve all threads listed in a JSON file or from stdin
# Input: JSON with thread IDs or text file with one thread ID per line

set -euo pipefail

OWNER="${1:-}"
REPO="${2:-}"
PR_NUMBER="${3:-}"
INPUT_FILE="${4:--}"  # Default to stdin

if [ -z "$OWNER" ] || [ -z "$REPO" ] || [ -z "$PR_NUMBER" ]; then
    echo "Usage: $0 <OWNER> <REPO> <PR_NUMBER> [INPUT_FILE]"
    echo ""
    echo "Examples:"
    echo "  $0 squirrel289 temple 42 threads.json"
    echo "  cat threads.txt | $0 squirrel289 temple 42"
    echo "  echo 'PRRT_abc123' | $0 squirrel289 temple 42"
    exit 1
fi

resolve_thread() {
    local thread_id=$1
    
    if [ -z "$thread_id" ]; then
        return
    fi
    
    echo "Resolving $thread_id..."
    
    if gh pr-review threads resolve "$PR_NUMBER" -R "$OWNER/$REPO" --thread-id "$thread_id" 2>/dev/null; then
        echo "✓ Resolved $thread_id"
    else
        echo "✗ Failed to resolve $thread_id"
        return 1
    fi
}

# Read input
if [ "$INPUT_FILE" = "-" ]; then
    # Read from stdin
    while read -r line; do
        # Try to extract thread ID from various formats
        if echo "$line" | grep -q "PRRT_"; then
            thread_id=$(echo "$line" | grep -oP 'PRRT_[a-zA-Z0-9]+' | head -1)
            resolve_thread "$thread_id"
        fi
    done
elif [ -f "$INPUT_FILE" ]; then
    # Detect if JSON or plain text
    if jq empty "$INPUT_FILE" 2>/dev/null; then
        # JSON file - extract thread IDs
        echo "Processing JSON file..."
        jq -r '.reviews[]?.comments[]?.thread_id // empty' "$INPUT_FILE" | while read -r thread_id; do
            resolve_thread "$thread_id"
        done
    else
        # Plain text file - one thread ID per line
        echo "Processing text file..."
        while read -r thread_id; do
            resolve_thread "$thread_id"
        done < "$INPUT_FILE"
    fi
else
    echo "Error: Input file '$INPUT_FILE' not found"
    exit 1
fi

echo "Done!"
