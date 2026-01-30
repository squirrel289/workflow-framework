# Phase 3: Implementation

Execute the plan created in Phase 2 by making necessary changes.

## Objectives

- Implement code changes as planned
- Update documentation
- Add or modify tests
- Maintain code quality standards
- Commit changes with clear messages
- Respond to reviewer questions

## Implementation Guidelines

### 1. Prepare Working Environment

```bash
# Ensure clean working tree
git status

# Sync with latest main
git fetch origin
git merge origin/main

# Create a clean state for changes
git stash  # if needed
```

### 2. Follow Execution Order

Implement changes according to the plan from Phase 2:
- **Critical path first** - Must be done sequentially
- **Parallel batches next** - Can be done simultaneously
- **Low priority last** - Time permitting

### 3. Implementation Best Practices

#### Code Changes

```python
# BEFORE: Address reviewer comment
# Reviewer (thread PRRT_abc123): "Add error handling here"
def authenticate(user):
    token = generate_token(user)
    return token

# AFTER: Implemented fix
def authenticate(user):
    try:
        token = generate_token(user)
        if not token:
            raise AuthenticationError("Token generation failed")
        return token
    except TokenError as e:
        logger.error(f"Authentication failed: {e}")
        raise AuthenticationError(f"Failed to authenticate user: {user.id}")
```

**Best practices:**
- Reference the thread ID in comments
- Preserve existing code structure when possible
- Follow project coding standards
- Add error handling where requested
- Include type hints if project uses them

#### Documentation Updates

```markdown
<!-- Reviewer (thread PRRT_def456): "Document the auth flow" -->

## Authentication Flow

1. User submits credentials
2. System validates against database
3. Token generated and returned
4. Token stored in session

Error cases are handled with `AuthenticationError` exceptions.
```

#### Test Additions

```python
# Tests for thread PRRT_abc123 (error handling)
def test_authenticate_handles_token_generation_failure():
    """Ensure authentication fails gracefully when token generation fails."""
    user = User(id=123, name="test")
    with patch('auth.generate_token', return_value=None):
        with pytest.raises(AuthenticationError):
            authenticate(user)

def test_authenticate_logs_errors():
    """Verify errors are logged for debugging."""
    user = User(id=123, name="test")
    with patch('auth.generate_token', side_effect=TokenError("DB error")):
        with patch('auth.logger') as mock_logger:
            with pytest.raises(AuthenticationError):
                authenticate(user)
            mock_logger.error.assert_called_once()
```

### 4. Quality Assurance

#### Run Tests After Each Change

```bash
# Run affected tests
pytest tests/test_auth.py -v

# Run full test suite
pytest

# Check code coverage
pytest --cov=src --cov-report=term-missing
```

#### Lint and Format

```bash
# Python
black src/
ruff check src/

# JavaScript/TypeScript
npm run lint
npm run format

# General
pre-commit run --all-files
```

#### Type Checking

```bash
# Python
mypy src/

# TypeScript
tsc --noEmit
```

### 5. Commit Strategy

#### Atomic Commits

Each commit should address one logical change:

```bash
# Good: One thread per commit
git add src/auth.py tests/test_auth.py
git commit -m "feat: add error handling to authenticate()

Addresses reviewer feedback in thread PRRT_abc123.
- Add try-except block for TokenError
- Raise AuthenticationError with context
- Add unit tests for error cases

Resolves: #42 (thread PRRT_abc123)"
```

#### Commit Message Format

```
<type>: <short summary>

<detailed explanation>
<thread reference>
<testing notes>

Resolves: #<PR number> (thread <thread_id>)
```

**Types:**
- `feat`: New feature or enhancement
- `fix`: Bug fix
- `docs`: Documentation only
- `test`: Adding or updating tests
- `refactor`: Code restructuring
- `style`: Formatting, whitespace
- `chore`: Maintenance tasks

### 6. Responding to Questions

For threads that require written responses:

```bash
# Use gh-pr-review to reply
gh pr-review comments reply <PR_NUMBER> -R owner/repo \
  --thread-id PRRT_abc123 \
  --body "I implemented error handling using custom exceptions as suggested. \
          See commit abc1234 for the implementation."
```

### 7. Handling Edge Cases

#### Conflicting Requirements

If comments conflict:
1. Ask for clarification in the thread
2. Tag relevant reviewers
3. Wait for resolution before implementing

```bash
gh pr-review comments reply <PR_NUMBER> -R owner/repo \
  --thread-id PRRT_conflict \
  --body "@reviewer1 @reviewer2 These two comments seem to conflict. \
          Which approach should I take?"
```

#### Scope Creep

If a comment requests changes beyond PR scope:
1. Acknowledge the feedback
2. Propose deferring to a separate issue/PR
3. Create the issue and reference it

```bash
# Create follow-up issue
gh issue create --title "Refactor auth module" \
  --body "Per PR #42 review, this should be addressed separately."

# Reference in comment
gh pr-review comments reply 42 -R owner/repo \
  --thread-id PRRT_xyz \
  --body "Good point. Created #123 to track this separately."
```

#### Cannot Reproduce Issue

If you can't reproduce a reported issue:
1. Document your testing approach
2. Ask for reproduction steps
3. Provide evidence (test output, screenshots)

### 8. Implementation Checklist

After each change:

- [ ] Code implemented as requested
- [ ] Tests added or updated
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Code linted and formatted
- [ ] No unrelated changes included
- [ ] Commit message references thread ID
- [ ] Ready for resolution

## Parallel Implementation Pattern

For items in parallel batches:

### Sequential Approach
```bash
# Change 1
edit src/file1.py
pytest tests/test_file1.py
git commit -m "fix: address comment in file1"

# Change 2
edit src/file2.py
pytest tests/test_file2.py
git commit -m "docs: update file2 docs"
```
See [[sequential-workflow]] for details.

### Parallel Approach (LLM Agents)
```bash
# Agent 1: file1.py changes
# Agent 2: file2.py changes
# Agent 3: documentation updates
# Agent 4: test additions
# All work independently, commit separately
```

See [[parallel-workflow]] for details.

## Verification Before Moving to Phase 4

Before marking threads as resolved:

1. **All tests pass** locally
2. **Code review** by yourself or teammate
3. **No merge conflicts** with main branch
4. **CI/CD passes** (if pushed)
5. **Changes match** reviewer requests exactly

## Next Phase

Once all implementations are complete and verified, proceed to [[04-resolution-verification]].

## Reference

- [[gh-pr-review-guide]]
- [[sequential-workflow]]
- [[parallel-workflow]]

---

[sequential-workflow]: ../patterns/sequential-workflow.md "Sequential PR Resolution Workflow"
[parallel-workflow]: ../patterns/parallel-workflow.md "Intra-PR Parallel Workflow"
[04-resolution-verification]: 04-resolution-verification.md "Phase 4: Resolution & Verification"
[gh-pr-review-guide]: ../../pr-comment-resolution/tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"

