# Implementation Phase Prompt Template

Use this prompt to guide an LLM through Phase 3: Implementation.

---

I need you to implement the changes requested in PR review comments.

## Context

- **Repository**: {OWNER}/{REPO}
- **PR Number**: {PR_NUMBER}
- **Execution Plan**: {path to plan file or paste plan here}
- **Current Batch**: {batch number or "all"}

## Available Information

The following files are provided for context:
- `unresolved.json`: Full thread data from Phase 1
- `execution_plan.json`: Ordered plan from Phase 2
- `context/files/`: Copies of affected files

## Tasks

### For Each Thread in Current Batch

#### 1. Read Thread Details

```bash
# Extract thread info
thread_id="{THREAD_ID}"
jq -r ".reviews[].comments[] | select(.thread_id == \"$thread_id\")" unresolved.json
```

#### 2. Understand the Request

Read the comment body and determine:
- What change is being requested?
- Why is this change needed?
- What is the scope of the change?
- Are there any edge cases to consider?

#### 3. Implement the Change

Read the file, make the necessary changes, and write it back:

```bash
# For Python files
file_path="{FILE_PATH}"
# Read file, make changes, write back
```

**Implementation Guidelines:**
- Follow the project's coding style
- Add error handling if requested
- Include type hints if the project uses them
- Preserve existing comments and structure
- Make minimal, focused changes

#### 4. Add or Update Tests

For each code change:
- Add unit tests for new functionality
- Update existing tests if behavior changes
- Ensure edge cases are covered
- Follow the project's testing conventions

```bash
# Run tests for this file
pytest tests/test_{filename}.py -v
```

#### 5. Verify Changes

Run the full test suite:

```bash
# Python
pytest

# JavaScript/TypeScript
npm test

# Go
go test ./...
```

#### 6. Commit Atomically

```bash
git add {files_changed}
git commit -m "fix: {brief description}

Addresses reviewer feedback in thread {thread_id}.
{Detailed explanation of changes}

Resolves: #{PR_NUMBER} (thread {thread_id})"
```

#### 7. Reply to Thread

```bash
gh pr-review comments reply {PR_NUMBER} -R {OWNER}/{REPO} \
  --thread-id {thread_id} \
  --body "Implemented in commit $(git rev-parse --short HEAD). 
  
  Changes:
  - {change 1}
  - {change 2}
  
  Tests: ✅ All passing"
```

## Error Handling

If tests fail:
1. Analyze the failure
2. Fix the issue
3. Re-run tests
4. If still failing after 3 attempts, report:

```bash
gh pr-review comments reply {PR_NUMBER} -R {OWNER}/{REPO} \
  --thread-id {thread_id} \
  --body "❌ Attempted to implement this change but encountered test failures:
  
  \`\`\`
  {test output}
  \`\`\`
  
  This may require manual intervention or clarification."
```

## Quality Checklist

Before marking implementation complete:

- [ ] Code implements the requested change exactly
- [ ] Code follows project style guidelines
- [ ] Tests added or updated appropriately
- [ ] All tests pass locally
- [ ] No unrelated changes included
- [ ] Commit message references thread ID
- [ ] Reply posted to thread with summary

## Output Format

After completing all threads in the batch, provide:

```
## Implementation Summary

### Completed Threads: {count}

1. [{thread_id}] {path}:{line}
   - Changes: {summary}
   - Tests: {pass/fail}
   - Commit: {sha}

2. ...

### Failed Threads: {count}

1. [{thread_id}] {path}:{line}
   - Reason: {explanation}
   - Recommended action: {suggestion}

### Test Results

\`\`\`
{pytest output or test summary}
\`\`\`

### Next Steps

{What should happen next - resolve threads, fix failures, etc.}
```

---

## Example Usage

Replace the placeholders:
- `{OWNER}`: Repository owner
- `{REPO}`: Repository name
- `{PR_NUMBER}`: PR number
- `{THREAD_ID}`: Specific thread to process
- `{FILE_PATH}`: Path to file being changed

Then copy this prompt and paste into your LLM interface.

## Tips

- Process one thread at a time for clarity
- Test after each change before moving to the next
- Commit after each successful change
- Keep changes focused and atomic
- Reference the thread ID in all commits and comments
