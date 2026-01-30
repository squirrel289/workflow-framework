# Interactive Workflow Pattern

Human-driven PR comment resolution with visual feedback and manual verification.

## When to Use

Use interactive workflows when:
- You want to review each change before applying
- Changes require nuanced judgment
- Complex code requires human understanding
- Learning the codebase through review process
- Suggestions are fuzzy or outdated

## Tools for Interactive Workflows

### Primary: gh-review-conductor (see [[gh-review-conductor-guide]])

Best for visual, interactive suggestion application.

```bash
gh extension install gh-tui-tools/gh-review-conductor
```

### Secondary: Manual with gh-pr-review (see [[gh-pr-review-guide]] )

Use `gh-pr-review` for data, make changes manually.

## Complete Interactive Workflow

### Phase 1: Browse Comments

```bash
# Launch interactive browser
gh review-conductor browse
```

**TUI Features:**
- Navigate with arrow keys
- View full comment context
- Jump to specific comments
- Open in web browser

### Phase 2: Understand Requests

For each comment:
1. Read the reviewer's feedback carefully
2. Look at the code context
3. Check if suggestion makes sense
4. Consider edge cases and implications

```bash
# View specific comment details
gh review-conductor browse COMMENT_ID

# Or use gh-pr-review for structured output
gh pr-review review view -R owner/repo --pr 42 --unresolved | jq
```

### Phase 3: Apply Changes Interactively

```bash
# Launch interactive suggestion applicator
gh review-conductor apply
```

**For each suggestion:**
1. **Preview** the diff (old vs new code)
2. **Assess** if the change is correct
3. **Choose** action:
   - `[a]ccept` - Apply the change
   - `[s]kip` - Skip for now
   - `[r]eject` - Don't apply
   - `[q]uit` - Exit

**Example prompt:**
```
┌─────────────────────────────────────┐
│ Suggestion in src/auth.py:42        │
│                                     │
│ - def authenticate(user):           │
│ + def authenticate(user: User):     │
│                                     │
│ [a]ccept [s]kip [r]eject [q]uit     │
└─────────────────────────────────────┘
```

### Phase 4: Manual Changes

For comments without suggestions:

```bash
# Read the comment
gh pr-review review view -R owner/repo --pr 42 --unresolved | \
  jq -r '.reviews[].comments[] | "[\(.thread_id)] \(.path):\(.line) - \(.body)"'

# Open file in your editor
code src/auth.py:42  # VS Code
vim +42 src/auth.py  # Vim
```

Make changes manually, following the reviewer's guidance.

### Phase 5: Test Changes

```bash
# Run affected tests
pytest tests/test_auth.py -v

# Run full suite
pytest

# Check coverage
pytest --cov=src --cov-report=term-missing
```

Fix any test failures before proceeding.

### Phase 6: Review Your Changes

```bash
# See what you changed
git diff

# Review specific file
git diff src/auth.py

# Interactive staging
git add -p
```

### Phase 7: Commit Atomically

```bash
# Commit one logical change at a time
git add src/auth.py tests/test_auth.py
git commit -m "fix: add type hints to authenticate()

Addresses reviewer feedback in thread PRRT_abc123.
Added User type hint to improve type safety.

Resolves: #42 (thread PRRT_abc123)"
```

### Phase 8: Respond to Comments

```bash
# Add reply explaining your changes
gh review-conductor comment COMMENT_ID \
  --body "Added type hints as requested. Commit: $(git rev-parse --short HEAD)"

# Or use gh-pr-review
gh pr-review comments reply 42 -R owner/repo \
  --thread-id PRRT_abc123 \
  --body "Implemented in commit $(git rev-parse --short HEAD)"
```

### Phase 9: Resolve Threads

```bash
# Resolve interactively
gh review-conductor resolve COMMENT_ID

# Or batch resolve after confirming all changes
gh review-conductor resolve --all

# Or use gh-pr-review for specific threads
gh pr-review threads resolve 42 -R owner/repo --thread-id PRRT_abc123
```

### Phase 10: Verify

```bash
# Check for remaining unresolved threads
gh pr-review review view -R owner/repo --pr 42 --unresolved

# View in browser
gh pr view 42 --web
```

## Interactive Patterns

### Pattern 1: One-by-One Processing

Process each comment individually with full context:

```bash
# Get thread list
gh pr-review review view -R owner/repo --pr 42 --unresolved > threads.json

# For each thread
jq -c '.reviews[].comments[]' threads.json | while read -r thread; do
  thread_id=$(echo "$thread" | jq -r '.thread_id')
  file=$(echo "$thread" | jq -r '.path')
  line=$(echo "$thread" | jq -r '.line')
  body=$(echo "$thread" | jq -r '.body')
  
  echo ""
  echo "═══════════════════════════════════════"
  echo "Thread: $thread_id"
  echo "File: $file:$line"
  echo "Request: $body"
  echo "═══════════════════════════════════════"
  
  # Open file at line
  code --goto "$file:$line"
  
  # Wait for user to make changes
  read -p "Press Enter when changes are complete..."
  
  # Run tests
  pytest "tests/test_$(basename "$file" .py).py"
  
  if [ $? -eq 0 ]; then
    # Commit
    read -p "Commit message (or skip): " commit_msg
    if [ -n "$commit_msg" ]; then
      git add "$file"
      git commit -m "$commit_msg (thread $thread_id)"
      
      # Resolve
      gh pr-review threads resolve 42 -R owner/repo --thread-id "$thread_id"
      echo "✓ Resolved $thread_id"
    fi
  else
    echo "✗ Tests failed, skipping"
  fi
done
```

### Pattern 2: Group by File

Process all comments for one file at once:

```bash
# Group threads by file
jq -r '.reviews[].comments[] | "\(.path)|\(.thread_id)|\(.body)"' threads.json | \
  sort -t'|' -k1,1 > grouped.txt

# Process each file
current_file=""
while IFS='|' read -r file thread_id body; do
  if [ "$file" != "$current_file" ]; then
    if [ -n "$current_file" ]; then
      # Commit previous file
      read -p "Commit changes to $current_file? (y/N) " confirm
      if [[ $confirm =~ ^[Yy]$ ]]; then
        git add "$current_file"
        git commit -m "fix: address review comments in $current_file"
      fi
    fi
    
    # Open new file
    current_file="$file"
    code "$file"
    echo ""
    echo "=== Processing $file ==="
  fi
  
  echo "  - [thread_id] $body"
done < grouped.txt
```

### Pattern 3: Review Then Bulk Apply

Review suggestions first, then apply all at once:

```bash
# 1. Review all suggestions
gh review-conductor browse

# 2. List them
gh review-conductor list

# 3. Apply all acceptable ones
gh review-conductor apply --all

# 4. Review the diff
git diff

# 5. If satisfied, commit
git add -A
git commit -m "fix: apply review suggestions

Applied all applicable review suggestions:
- Add error handling
- Update type hints
- Fix formatting

Multiple threads resolved."

# 6. Resolve all
gh review-conductor resolve --all
```

## Tips for Interactive Workflows

### Use Git Stash for Context Switching

```bash
# Save work in progress
git stash save "WIP: addressing review comments"

# Work on something else
git checkout main

# Return to work
git checkout review-branch
git stash pop
```

### Create Checkpoints

```bash
# Create a checkpoint branch before major changes
git branch checkpoint-before-review

# If something goes wrong
git reset --hard checkpoint-before-review
```

### Use Interactive Rebase for Cleanup

```bash
# After making many small commits
git rebase -i HEAD~10

# Squash related commits together
# Reword commit messages for clarity
```

### Keep Notes

```bash
# Create a resolution log
echo "Thread PRRT_abc123: Added type hints" >> resolution_log.txt
echo "Thread PRRT_def456: Fixed error handling" >> resolution_log.txt

# Reference when writing summary
cat resolution_log.txt
```

## Keyboard Shortcuts (gh-review-conductor)

| Key | Action |
|-----|--------|
| `↑/↓` | Navigate comments |
| `Enter` | View details |
| `o` | Open in browser |
| `a` | Accept suggestion |
| `s` | Skip suggestion |
| `r` | Reject suggestion |
| `q` | Quit |
| `i` | Refresh |

## Advantages of Interactive Workflows

1. **Human judgment** - You make the final call on each change
2. **Learning** - Understand the codebase better
3. **Safety** - Catch mistakes before committing
4. **Flexibility** - Handle edge cases and exceptions
5. **Context** - See the full picture, not just snippets

## When to Switch to Automation

Consider automating when:
- You've reviewed 10+ threads and they're all straightforward
- Suggestions are consistent and pattern-based
- Time pressure requires faster resolution
- Changes are low-risk (docs, formatting, etc.)

See [[full-automation-guide]] for end-to-end automation implementation.

## Related

- [[gh-review-conductor-guide]]
- [[gh-pr-review-guide]]
- [[parallel-workflow]] - For batch work

---

[full-automation-guide]: ../../pr-comment-resolution/tools/full-automation-guide.md "Full Automation Guide"
[gh-review-conductor-guide]: ../../pr-comment-resolution/tools/gh-review-conductor-guide.md "gh-review-conductor Tool Guide"
[gh-pr-review-guide]: ../../pr-comment-resolution/tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"
[parallel-workflow]: ./parallel-workflow.md "Parallel Processing Pattern"
