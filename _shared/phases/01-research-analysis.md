# Phase 1: Research & Analysis

Gather comprehensive information about the PR before making any changes.

## Objectives

- Understand the current PR context (branch, changes, status)
- Identify all unresolved review comments and conversations
- List to-do items mentioned in comments
- Note requested changes from code reviews
- Catalog questions that need responses
- Determine dependencies between requested changes

## Context Establishment

### Essential Information to Gather

1. **Current Branch & PR Number**
   ```bash
   git branch --show-current
   gh pr status
   ```

2. **PR Metadata**
   - Title and description
   - Review status (approved, changes requested, pending)
   - Associated issue links
   - CI/CD status

3. **Unresolved Comments**
   - Inline code comments
   - General discussion threads
   - Review-level feedback

4. **Project Structure**
   - Key directories and files affected
   - Test locations
   - Documentation paths

## Recommended Approach: gh-pr-review (see [[gh-review-conductor-guide]])

Use `gh-pr-review` for deterministic, LLM-optimized output:

```bash
# Install (if not already installed)
gh extension install agynio/gh-pr-review

# Fetch all unresolved threads (JSON output)
gh pr-review review view -R owner/repo --pr 42 --unresolved --not_outdated
```

### Output Analysis

The JSON output includes:
- `reviews[]` - All review objects
- `comments[]` - Inline comments with file/line context
- `thread_id` - Unique identifier for each thread
- `is_resolved` - Resolution status
- `thread_comments[]` - Replies and discussions

### Key Fields to Extract

```json
{
  "reviews": [
    {
      "id": "PRR_...",
      "state": "COMMENTED",
      "author_login": "reviewer",
      "comments": [
        {
          "thread_id": "PRRT_...",
          "path": "src/file.py",
          "line": 42,
          "body": "Please add error handling",
          "is_resolved": false,
          "thread_comments": []
        }
      ]
    }
  ]
}
```

## Alternative Approaches

### Using GitHub CLI (less structured)
```bash
gh pr view --comments
gh pr view --json reviews,reviewThreads,comments
```

### Using GitHub GraphQL API
```bash
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewThreads(first: 100) {
          nodes {
            id
            isResolved
            comments(first: 50) {
              nodes {
                body
                author { login }
              }
            }
          }
        }
      }
    }
  }
'
```

## Categorize Findings

Group identified items by type:

### 1. Code Changes Required
- Logic bugs or errors
- Performance improvements
- Code style/formatting
- Missing error handling

### 2. Documentation Updates
- README changes
- Inline code comments
- API documentation
- Architecture diagrams

### 3. Questions to Answer
- Design decisions
- Implementation approaches
- Clarifications on requirements

### 4. Test Additions
- Unit tests
- Integration tests
- Edge case coverage

## Output Artifacts

At the end of this phase, you should have:

1. **Unresolved threads JSON** (`unresolved.json`)
2. **Categorized list** of changes needed
3. **Dependency graph** (which changes must happen first)
4. **Thread ID mapping** (thread_id → description)

## Next Phase

Once research is complete, proceed to [[02-planning]].

## Reference

- [[gh-review-conductor-guide]]
- [[github-apis]]

---

[gh-review-conductor-guide]: ../../pr-comment-resolution/tools/gh-review-conductor-guide.md "gh-review-conductor Tool Guide"
[github-apis]: ../tools/github-apis.md "GitHub APIs Reference"
[02-planning]: 02-planning.md "Phase 2: Planning"