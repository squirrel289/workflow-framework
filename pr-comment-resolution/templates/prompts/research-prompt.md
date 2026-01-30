# Research Phase Prompt Template

Use this prompt to guide an LLM through Phase 1: Research & Analysis.

---

I need you to analyze a pull request and identify all unresolved review comments.

## PR Information
- **Repository**: {OWNER}/{REPO}
- **PR Number**: {PR_NUMBER}
- **Current Branch**: {BRANCH_NAME}

## Tasks

### 1. Fetch Unresolved Threads

Run the following command and analyze the output:

```bash
gh pr-review review view -R {OWNER}/{REPO} --pr {PR_NUMBER} --unresolved --not_outdated
```

### 2. Extract Key Information

For each unresolved thread, extract:
- `thread_id`: The unique identifier (PRRT_...)
- `path`: The file being commented on
- `line`: The line number (if applicable)
- `body`: The reviewer's comment/request
- `author_login`: Who made the comment
- `is_outdated`: Whether the comment is outdated (should be false)

### 3. Categorize Comments

Group the comments into these categories:
- **Code Changes**: Logic fixes, refactoring, style improvements
- **Tests**: Missing tests, test improvements
- **Documentation**: README updates, inline comments, API docs
- **Questions**: Clarifications needed before proceeding

### 4. Identify Dependencies

Analyze whether changes can be made independently or have dependencies:
- Same file = potential dependency
- Different files = likely independent
- Tests depend on code changes
- Documentation depends on implementation

### 5. Output Format

Provide your analysis in this format:

```
## Research Summary

### Overview
- Total unresolved threads: {count}
- Files affected: {file_list}
- Estimated complexity: {low|medium|high}

### Categorized Threads

#### Code Changes ({count})
1. [{thread_id}] {path}:{line} - {summary of request}
2. ...

#### Tests ({count})
1. [{thread_id}] {path}:{line} - {summary of request}
2. ...

#### Documentation ({count})
1. [{thread_id}] {path}:{line} - {summary of request}
2. ...

#### Questions ({count})
1. [{thread_id}] {path}:{line} - {question}
2. ...

### Dependencies

- Thread {A} depends on {B} because {reason}
- Threads {C}, {D}, {E} are independent
- ...

### Recommended Execution Order

1. {thread_id} - {reason}
2. {thread_id} - {reason}
3. ...

### Next Steps

Based on this analysis:
1. {recommended action}
2. {recommended action}
```

### 6. Save Artifacts

Save the raw JSON output to `unresolved.json` for later phases.

---

## Example Usage

Replace the placeholders:
- `{OWNER}`: Repository owner (e.g., "squirrel289")
- `{REPO}`: Repository name (e.g., "temple")
- `{PR_NUMBER}`: PR number (e.g., "42")
- `{BRANCH_NAME}`: Current branch name

Then copy this prompt and paste into your LLM interface.
