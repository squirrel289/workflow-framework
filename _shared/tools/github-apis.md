# GitHub APIs Reference

Direct access to GitHub REST and GraphQL APIs for PR comment resolution.

## When to Use

Use GitHub APIs directly when:
- `gh-pr-review` doesn't support your use case
- You need custom data transformations
- Building custom tooling or CI/CD integration
- Platform doesn't support `gh` CLI

## Authentication

### Using Personal Access Token (PAT)

```bash
export GITHUB_TOKEN="ghp_your_token_here"

# Or use gh auth
gh auth login
gh auth token
```

### Required Scopes

- `repo` - Full repository access
- `write:discussion` - For resolving threads
- `read:org` - For organization repositories

## GraphQL API

### Get PR Review Threads

```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        title
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            isOutdated
            comments(first: 50) {
              nodes {
                id
                body
                path
                position
                author {
                  login
                }
                createdAt
              }
            }
          }
        }
      }
    }
  }
' -f owner='squirrel289' -f repo='temple' -F pr=42
```

### Resolve a Thread

```bash
gh api graphql -f query='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {threadId: $threadId}) {
      thread {
        id
        isResolved
      }
    }
  }
' -f threadId='PRRT_kwDOAAABbcdEFG12'
```

### Add Comment to Thread

```bash
gh api graphql -f query='
  mutation($pullRequestId: ID!, $body: String!, $commitOID: GitObjectID, $path: String!, $position: Int!) {
    addPullRequestReviewComment(input: {
      pullRequestId: $pullRequestId
      body: $body
      commitOID: $commitOID
      path: $path
      position: $position
    }) {
      comment {
        id
      }
    }
  }
' -f pullRequestId='PR_...' -f body='Fixed' -f path='src/auth.py' -F position=42
```

## REST API

### List PR Reviews

```bash
gh api /repos/{owner}/{repo}/pulls/{pr_number}/reviews
```

### List Review Comments

```bash
gh api /repos/{owner}/{repo}/pulls/{pr_number}/comments
```

### Create Review Comment Reply

```bash
gh api -X POST /repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body='Fixed in commit abc123'
```

### Update Review Comment

```bash
gh api -X PATCH /repos/{owner}/{repo}/pulls/comments/{comment_id} \
  -f body='Updated comment'
```

## Complete Examples

### Fetch All Unresolved Threads (GraphQL)

```bash
#!/bin/bash

OWNER="squirrel289"
REPO="temple"
PR=42

QUERY='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          comments(first: 50) {
            nodes {
              id
              body
              path
              position
              author { login }
              createdAt
            }
          }
        }
      }
    }
  }
}
'

gh api graphql -f query="$QUERY" \
  -f owner="$OWNER" \
  -f repo="$REPO" \
  -F pr=$PR | \
  jq '.data.repository.pullRequest.reviewThreads.nodes[] | select(.isResolved == false and .isOutdated == false)'
```

### Resolve All Threads (GraphQL)

```bash
#!/bin/bash

# Read thread IDs from file or stdin
while read -r thread_id; do
  MUTATION='
  mutation($threadId: ID!) {
    resolveReviewThread(input: {threadId: $threadId}) {
      thread {
        id
        isResolved
      }
    }
  }
  '
  
  gh api graphql -f query="$MUTATION" -f threadId="$thread_id"
  echo "Resolved $thread_id"
done < thread_ids.txt
```

### Create PR Review (REST)

```bash
gh api -X POST /repos/{owner}/{repo}/pulls/{pr_number}/reviews \
  -f body='Reviewing changes' \
  -f event='COMMENT' \
  -f comments='[
    {
      "path": "src/auth.py",
      "position": 42,
      "body": "Consider adding error handling here"
    }
  ]'
```

## Python Client Example

```python
import os
import requests

GITHUB_TOKEN = os.environ["GITHUB_TOKEN"]
GITHUB_API = "https://api.github.com"
HEADERS = {
    "Authorization": f"Bearer {GITHUB_TOKEN}",
    "Accept": "application/vnd.github.v3+json"
}

def get_pr_reviews(owner, repo, pr_number):
    """Get all reviews for a PR."""
    url = f"{GITHUB_API}/repos/{owner}/{repo}/pulls/{pr_number}/reviews"
    response = requests.get(url, headers=HEADERS)
    response.raise_for_status()
    return response.json()

def get_review_comments(owner, repo, pr_number):
    """Get all review comments for a PR."""
    url = f"{GITHUB_API}/repos/{owner}/{repo}/pulls/{pr_number}/comments"
    response = requests.get(url, headers=HEADERS)
    response.raise_for_status()
    return response.json()

def resolve_thread_graphql(thread_id):
    """Resolve a review thread using GraphQL."""
    url = f"{GITHUB_API}/graphql"
    query = """
    mutation($threadId: ID!) {
      resolveReviewThread(input: {threadId: $threadId}) {
        thread {
          id
          isResolved
        }
      }
    }
    """
    
    response = requests.post(
        url,
        json={"query": query, "variables": {"threadId": thread_id}},
        headers=HEADERS
    )
    response.raise_for_status()
    return response.json()

# Usage
owner = "squirrel289"
repo = "temple"
pr = 42

reviews = get_pr_reviews(owner, repo, pr)
comments = get_review_comments(owner, repo, pr)

print(f"Found {len(reviews)} reviews and {len(comments)} comments")
```

## Rate Limits

### Check Rate Limit Status

```bash
gh api rate_limit
```

**Limits:**
- Authenticated: 5,000 requests/hour
- GraphQL: 5,000 points/hour (complex queries use more points)

### Handle Rate Limiting

```bash
check_rate_limit() {
  REMAINING=$(gh api rate_limit | jq '.rate.remaining')
  if [ "$REMAINING" -lt 100 ]; then
    echo "Rate limit low: $REMAINING remaining"
    RESET=$(gh api rate_limit | jq '.rate.reset')
    WAIT=$((RESET - $(date +%s)))
    echo "Waiting ${WAIT}s for rate limit reset..."
    sleep $WAIT
  fi
}

# Before making API calls
check_rate_limit
gh api graphql -f query='...'
```

## Error Handling

### Common Errors

**401 Unauthorized:**
```json
{
  "message": "Bad credentials",
  "documentation_url": "https://docs.github.com/rest"
}
```
→ Check GITHUB_TOKEN is set and valid

**403 Forbidden:**
```json
{
  "message": "Resource not accessible by integration",
  "documentation_url": "https://docs.github.com/rest/reference/pulls"
}
```
→ Check token scopes

**404 Not Found:**
```json
{
  "message": "Not Found",
  "documentation_url": "https://docs.github.com/rest"
}
```
→ Check owner/repo/PR number

**422 Unprocessable Entity:**
```json
{
  "message": "Validation Failed",
  "errors": [...]
}
```
→ Check request payload format

## Reference Documentation

- [GitHub REST API](https://docs.github.com/en/rest)
- [GitHub GraphQL API](https://docs.github.com/en/graphql)
- [Pull Request Reviews API](https://docs.github.com/en/rest/pulls/reviews)
- [Pull Request Comments API](https://docs.github.com/en/rest/pulls/comments)
- [GraphQL Explorer](https://docs.github.com/en/graphql/overview/explorer)

## Related

- [[gh-pr-review-guide]] - Recommended higher-level tool
- [gh CLI Manual](https://cli.github.com/manual/) - GitHub CLI reference

---

[gh-pr-review-guide]: ../../pr-comment-resolution/tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"