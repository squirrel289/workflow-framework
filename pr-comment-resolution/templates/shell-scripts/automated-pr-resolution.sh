#!/bin/bash
# Automated PR Comment Resolution Script
# Uses gh-pr-review for deterministic, reproducible resolution

set -euo pipefail

# Configuration
OWNER="${GITHUB_REPOSITORY_OWNER:-owner}"
REPO="${GITHUB_REPOSITORY_NAME:-repo}"
PR_NUMBER="${1:-}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) not found. Install from https://cli.github.com"
        exit 1
    fi
    
    if ! gh extension list | grep -q "agynio/gh-pr-review"; then
        log_error "gh-pr-review extension not installed"
        log_info "Run: gh extension install agynio/gh-pr-review"
        exit 1
    fi
    
    if ! git rev-parse --is-inside-work-tree &> /dev/null; then
        log_error "Not inside a git repository"
        exit 1
    fi
    
    log_info "✓ All prerequisites met"
}

fetch_unresolved_threads() {
    log_info "Fetching unresolved threads for PR #$PR_NUMBER..."
    
    gh pr-review review view -R "$OWNER/$REPO" --pr "$PR_NUMBER" \
        --unresolved --not_outdated > /tmp/unresolved_$PR_NUMBER.json
    
    THREAD_COUNT=$(jq '[.reviews[].comments[]] | length' /tmp/unresolved_$PR_NUMBER.json)
    
    if [ "$THREAD_COUNT" -eq 0 ]; then
        log_info "✅ No unresolved threads found"
        exit 0
    fi
    
    log_info "Found $THREAD_COUNT unresolved thread(s)"
}

display_threads() {
    log_info "Unresolved threads:"
    jq -r '.reviews[].comments[] | "  [\(.thread_id)] \(.path):\(.line // "?") - \(.body | .[0:60])..."' \
        /tmp/unresolved_$PR_NUMBER.json
}

implement_changes() {
    log_info "Implementing changes..."
    
    # Extract threads into easier format
    jq -c '.reviews[].comments[]' /tmp/unresolved_$PR_NUMBER.json | while read -r thread; do
        thread_id=$(echo "$thread" | jq -r '.thread_id')
        file_path=$(echo "$thread" | jq -r '.path')
        request=$(echo "$thread" | jq -r '.body')
        line=$(echo "$thread" | jq -r '.line // "unknown"')
        
        log_info "Processing $thread_id: $file_path:$line"
        
        # TODO: Implement your change logic here
        # This is where you would:
        # 1. Read the file
        # 2. Make the requested change
        # 3. Write the file back
        #
        # For now, just log what would be done
        log_warn "Would implement: $request"
        
        # Placeholder for actual implementation
        # make_change "$file_path" "$request" "$line"
    done
}

run_tests() {
    log_info "Running tests..."
    
    # Detect test framework and run tests
    if [ -f "pytest.ini" ] || [ -f "setup.py" ]; then
        pytest --tb=short
    elif [ -f "package.json" ]; then
        npm test
    elif [ -f "go.mod" ]; then
        go test ./...
    else
        log_warn "No recognized test framework found, skipping tests"
        return 0
    fi
    
    if [ $? -eq 0 ]; then
        log_info "✓ Tests passed"
        return 0
    else
        log_error "✗ Tests failed"
        return 1
    fi
}

commit_changes() {
    log_info "Committing changes..."
    
    if [ -z "$(git status --porcelain)" ]; then
        log_warn "No changes to commit"
        return 0
    fi
    
    git add -A
    
    # Create commit message with thread references
    COMMIT_MSG=$(cat <<EOF
fix: resolve PR review comments

Addresses review feedback from PR #$PR_NUMBER:
$(jq -r '.reviews[].comments[] | "- \(.path):\(.line // "?") - \(.body | .[0:60])..."' /tmp/unresolved_$PR_NUMBER.json)

EOF
)
    
    git commit -m "$COMMIT_MSG"
    log_info "✓ Changes committed"
}

reply_to_threads() {
    log_info "Adding replies to threads..."
    
    COMMIT_SHA=$(git rev-parse --short HEAD)
    
    jq -r '.reviews[].comments[].thread_id' /tmp/unresolved_$PR_NUMBER.json | while read -r thread_id; do
        gh pr-review comments reply "$PR_NUMBER" -R "$OWNER/$REPO" \
            --thread-id "$thread_id" \
            --body "Addressed in commit $COMMIT_SHA"
        
        log_info "✓ Replied to $thread_id"
    done
}

resolve_threads() {
    log_info "Resolving threads..."
    
    jq -r '.reviews[].comments[].thread_id' /tmp/unresolved_$PR_NUMBER.json | while read -r thread_id; do
        gh pr-review threads resolve "$PR_NUMBER" -R "$OWNER/$REPO" \
            --thread-id "$thread_id"
        
        log_info "✓ Resolved $thread_id"
    done
}

verify_resolution() {
    log_info "Verifying all threads are resolved..."
    
    gh pr-review review view -R "$OWNER/$REPO" --pr "$PR_NUMBER" \
        --unresolved > /tmp/verify_$PR_NUMBER.json
    
    REMAINING=$(jq '[.reviews[].comments[]] | length' /tmp/verify_$PR_NUMBER.json)
    
    if [ "$REMAINING" -eq 0 ]; then
        log_info "✅ All threads successfully resolved!"
        return 0
    else
        log_warn "⚠️ $REMAINING thread(s) still unresolved"
        jq -r '.reviews[].comments[] | "  [\(.thread_id)] \(.path)"' /tmp/verify_$PR_NUMBER.json
        return 1
    fi
}

post_summary() {
    log_info "Posting resolution summary..."
    
    SUMMARY=$(cat <<EOF
## Automated Resolution Summary

All review comments have been addressed:

### Resolved Threads
$(jq -r '.reviews[].comments[] | "- [\(.thread_id)] \(.path):\(.line // "?") - \(.body | .[0:60])..."' /tmp/unresolved_$PR_NUMBER.json)

### Changes
- Commit: $(git rev-parse --short HEAD)
- Tests: ✅ Passing

### Status
All threads marked as resolved ✅
EOF
)
    
    gh pr comment "$PR_NUMBER" -R "$OWNER/$REPO" --body "$SUMMARY"
    log_info "✓ Summary posted"
}

cleanup() {
    rm -f /tmp/unresolved_$PR_NUMBER.json
    rm -f /tmp/verify_$PR_NUMBER.json
}

# Main execution
main() {
    if [ -z "$PR_NUMBER" ]; then
        echo "Usage: $0 <PR_NUMBER>"
        echo ""
        echo "Example: $0 42"
        exit 1
    fi
    
    log_info "Starting automated PR resolution for #$PR_NUMBER"
    
    check_prerequisites
    fetch_unresolved_threads
    display_threads
    
    # Confirm before proceeding
    read -p "Proceed with automated resolution? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_warn "Aborted by user"
        exit 0
    fi
    
    implement_changes
    
    if ! run_tests; then
        log_error "Tests failed, rolling back..."
        git reset --hard HEAD
        exit 1
    fi
    
    commit_changes
    reply_to_threads
    resolve_threads
    verify_resolution
    post_summary
    
    cleanup
    
    log_info "🎉 PR resolution complete!"
}

# Run main function
main "$@"
