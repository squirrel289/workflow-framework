# gh-pr-review Tool Guide

Comprehensive reference for `gh-pr-review`, the recommended tool for programmatic PR comment resolution.

## Why gh-pr-review?

**Optimized for LLMs and automation:**
- Single GraphQL call returns complete review context
- Deterministic, stable JSON output
- Minimal token usage (omits nulls, includes only essential fields)
- Server-side filtering reduces payload size
- Programmatic thread resolution with predictable responses

## Installation

```bash
# Install the extension
gh extension install agynio/gh-pr-review

# Verify installation
gh pr-review --version

# Update to latest version
gh extension upgrade agynio/gh-pr-review
```

## Core Commands

### 1. View Reviews (`review view`)

Fetch complete PR review data with inline comments and threads.

```bash
# Basic usage - all reviews and threads
gh pr-review review view -R owner/repo --pr 42

# Unresolved threads only (recommended for resolution workflow)
gh pr-review review view -R owner/repo --pr 42 --unresolved --not_outdated

# Filter by reviewer
gh pr-review review view -R owner/repo --pr 42 --reviewer alice

# Filter by review state
gh pr-review review view -R owner/repo --pr 42 --states CHANGES_REQUESTED,COMMENTED

# Keep only last N replies per thread (reduce token usage)
gh pr-review review view -R owner/repo --pr 42 --tail 1

# Include GraphQL node IDs for comments
gh pr-review review view -R owner/repo --pr 42 --include-comment-node-id
```

**Output structure:**
```json
{
  "reviews": [
    {
      "id": "PRR_kwDOAAABbcdEFG12",
      "state": "CHANGES_REQUESTED",
      "author_login": "reviewer1",
      "submitted_at": "2026-01-15T10:30:00Z",
      "comments": [
        {
          "thread_id": "PRRT_kwDOAAABbcdEFG12",
          "path": "src/auth.py",
          "line": 42,
          "author_login": "reviewer1",
          "body": "Please add error handling here",
          "created_at": "2026-01-15T10:30:00Z",
          "is_resolved": false,
          "is_outdated": false,
          "thread_comments": []
        }
      ]
    }
  ]
}
```

### 2. Start Pending Review (`review --start`)

Create a new pending review for adding inline comments.

```bash
gh pr-review review --start -R owner/repo 42
```

**Output:**
```json
{
  "id": "PRR_kwDOAAABbcdEFG12",
  "state": "PENDING"
}
```

**Note:** Save the `id` for adding comments and submitting.

### 3. Add Inline Comments (`review --add-comment`)

Add comments to a pending review.

```bash
gh pr-review review --add-comment \
  --review-id PRR_kwDOAAABbcdEFG12 \
  --path src/auth.py \
  --line 42 \
  --body "Consider using custom exception here" \
  -R owner/repo 42
```

**Output:**
```json
{
  "id": "PRRT_kwDOAAABbcdEFG12",
  "path": "src/auth.py",
  "is_outdated": false,
  "line": 42
}
```

### 4. Submit Review (`review --submit`)

Finalize and submit a pending review.

```bash
# Submit with approval
gh pr-review review --submit \
  --review-id PRR_kwDOAAABbcdEFG12 \
  --event APPROVE \
  --body "Looks good!" \
  -R owner/repo 42

# Submit requesting changes
gh pr-review review --submit \
  --review-id PRR_kwDOAAABbcdEFG12 \
  --event REQUEST_CHANGES \
  --body "Please address the comments" \
  -R owner/repo 42

# Submit as comment only
gh pr-review review --submit \
  --review-id PRR_kwDOAAABbcdEFG12 \
  --event COMMENT \
  --body "Some notes" \
  -R owner/repo 42
```

**Output:**
```json
{
  "status": "Review submitted successfully"
}
```

### 5. Reply to Threads (`comments reply`)

Add replies to existing review threads.

```bash
# Basic reply
gh pr-review comments reply 42 -R owner/repo \
  --thread-id PRRT_kwDOAAABbcdEFG12 \
  --body "Fixed in commit abc1234"

# Reply from within a pending review
gh pr-review comments reply 42 -R owner/repo \
  --thread-id PRRT_kwDOAAABbcdEFG12 \
  --review-id PRR_kwDOAAABbcdEFG12 \
  --body "I'll address this in the pending review"
```

### 6. List Threads (`threads list`)

Enumerate review threads with filtering.

```bash
# All threads
gh pr-review threads list -R owner/repo 42

# Unresolved threads only
gh pr-review threads list --unresolved -R owner/repo 42

# Your threads only
gh pr-review threads list --mine -R owner/repo 42

# Combine filters
gh pr-review threads list --unresolved --mine --not_outdated -R owner/repo 42
```

**Output:**
```json
[
  {
    "threadId": "PRRT_kwDOAAABbcdEFG12",
    "isResolved": false,
    "path": "src/auth.py",
    "line": 42,
    "isOutdated": false
  }
]
```

### 7. Resolve Threads (`threads resolve`)

Mark threads as resolved.

```bash
# Resolve single thread
gh pr-review threads resolve 42 -R owner/repo \
  --thread-id PRRT_kwDOAAABbcdEFG12

# Batch resolve (shell loop)
while read -r thread_id; do
  gh pr-review threads resolve 42 -R owner/repo --thread-id "$thread_id"
done < thread_ids.txt
```

**Output:**
```json
{
  "thread_node_id": "PRRT_kwDOAAABbcdEFG12",
  "is_resolved": true
}
```

### 8. Unresolve Threads (`threads unresolve`)

Reopen resolved threads.

```bash
gh pr-review threads unresolve 42 -R owner/repo \
  --thread-id PRRT_kwDOAAABbcdEFG12
```

## Complete Workflow Example

### Scenario: Address all unresolved comments

```bash
#!/bin/bash
OWNER="owner"
REPO="repo"
PR=42

# 1. Fetch unresolved threads
echo "Fetching unresolved comments..."
gh pr-review review view -R "$OWNER/$REPO" --pr "$PR" --unresolved --not_outdated > unresolved.json

# 2. Parse and display
echo "Unresolved threads:"
jq -r '.reviews[].comments[] | "[\(.thread_id)] \(.path):\(.line) - \(.body)"' unresolved.json

# 3. Make changes to address comments
# (your implementation here)

# 4. Reply to threads with updates
jq -r '.reviews[].comments[].thread_id' unresolved.json | while read -r thread_id; do
  gh pr-review comments reply "$PR" -R "$OWNER/$REPO" \
    --thread-id "$thread_id" \
    --body "Addressed in latest commit"
done

# 5. Resolve all threads
jq -r '.reviews[].comments[].thread_id' unresolved.json | while read -r thread_id; do
  gh pr-review threads resolve "$PR" -R "$OWNER/$REPO" --thread-id "$thread_id"
  echo "✓ Resolved $thread_id"
done

echo "All threads resolved!"
```

## Filter Reference

### Available Filters

| Filter | Description | Example |
|--------|-------------|---------|
| `--reviewer <login>` | Filter by reviewer username | `--reviewer alice` |
| `--states <list>` | Comma-separated review states | `--states APPROVED,CHANGES_REQUESTED` |
| `--unresolved` | Keep only unresolved threads | `--unresolved` |
| `--not_outdated` | Exclude outdated threads | `--not_outdated` |
| `--mine` | Your threads only | `--mine` |
| `--tail <n>` | Keep last N replies per thread | `--tail 1` |
| `--include-comment-node-id` | Add GraphQL node IDs | `--include-comment-node-id` |

### Review States

- `APPROVED` - Approved the changes
- `CHANGES_REQUESTED` - Requested changes
- `COMMENTED` - General comment without approval/rejection
- `DISMISSED` - Review was dismissed

## LLM Integration Patterns

### Minimal Context for Token Efficiency

```bash
# Get only what's needed
gh pr-review review view -R owner/repo --pr 42 \
  --unresolved \
  --not_outdated \
  --tail 0  # No replies, just parent comments
```

### Parse JSON in LLM Prompts

```python
import json
import subprocess

# Fetch data
result = subprocess.run(
    ["gh", "pr-review", "review", "view", "-R", "owner/repo", "--pr", "42", "--unresolved"],
    capture_output=True,
    text=True
)
data = json.loads(result.stdout)

# Extract thread IDs and descriptions
threads = []
for review in data["reviews"]:
    for comment in review.get("comments", []):
        threads.append({
            "thread_id": comment["thread_id"],
            "file": comment["path"],
            "line": comment.get("line"),
            "request": comment["body"]
        })

# Pass to LLM with minimal context
print(json.dumps(threads, indent=2))
```

## Error Handling

### GraphQL Errors

```json
{
  "status": "Review submission failed",
  "errors": [
    { "message": "mutation failed", "path": ["mutation", "submitPullRequestReview"] }
  ]
}
```

**Common errors:**
- Invalid review ID (must be `PRR_...` GraphQL node, not numeric)
- Invalid thread ID (must be `PRRT_...` GraphQL node)
- Review already submitted
- Insufficient permissions

### Exit Codes

- `0` - Success
- `1` - GraphQL error or invalid input
- `2` - Authentication error

## Performance Tips

1. **Use filtering** - Don't fetch all data if you only need unresolved threads
2. **Limit replies** - Use `--tail 1` to reduce payload size
3. **Cache results** - Save JSON output to file, process locally
4. **Batch operations** - Use shell loops for multiple threads

## Reference Documentation

- [Official README](https://github.com/agynio/gh-pr-review)
- [AGENTS.md](https://github.com/agynio/gh-pr-review/blob/main/docs/AGENTS.md) - Agent-specific workflows
- [SCHEMAS.md](https://github.com/agynio/gh-pr-review/blob/main/docs/SCHEMAS.md) - JSON schema reference
- [USAGE.md](https://github.com/agynio/gh-pr-review/blob/main/docs/USAGE.md) - Command examples

## Related

- [[github-apis]] - Direct GraphQL/REST API
- [[gh-review-conductor-guide]] - Alternative interactive tool

---

[github-apis]: ../../_shared/tools/github-apis.md "GitHub APIs Reference"
[gh-review-conductor-guide]: gh-review-conductor-guide.md "gh-review-conductor Tool Guide"