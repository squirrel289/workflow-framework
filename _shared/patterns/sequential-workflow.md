# Sequential PR Resolution Workflow

This guide describes the **default, non-interactive, sequential process** for resolving all comments in a pull request using an LLM agent or automation script. No parallelization, batching, or human gates—just process the PR from start to finish.

---

## Step-by-Step Instructions

### 1. Research & Analysis
- Load: [[01-research-analysis]]
- Load: [[gh-pr-review-guide]]
- Gather all unresolved threads, PR metadata, and context as described.
- Output: List of unresolved comments and files to change.

### 2. Planning
- Load: [[02-planning]]
- Review the list of comments and group them by file or logical dependency.
- Decide the order in which to address them (simple → complex is recommended).

### 3. Implementation
- Load: [[03-implementation]]
- For each unresolved comment:
  - Make the required code/documentation change.
  - Add or update tests as needed.
  - Commit the change with a clear message referencing the comment.
- Repeat until all comments are addressed.

### 4. Resolution & Verification
- Load: [[04-resolution-verification]]
- Mark each thread as resolved in the PR interface or via CLI.
- Verify all tests pass and the PR is ready for review/merge.

---

## Minimal Agent Prompt

> "Process PR #<number> sequentially using the instructions in sequential-workflow.md. Do not parallelize, batch, or request human input."

---

## See Also
- [[full-automation-guide]] — for complete code/script examples
- [[START_HERE]] — for mode selection and advanced workflows

---

[01-research-analysis]: ../phases/01-research-analysis.md "Phase 1: Research & Analysis"
[02-planning]: ../phases/02-planning.md "Phase 2: Planning"
[03-implementation]: ../phases/03-implementation.md "Phase 3: Implementation"
[04-resolution-verification]: ../phases/04-resolution-verification.md "Phase 4: Resolution & Verification"
[gh-pr-review-guide]: ../../pr-comment-resolution/tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"
[full-automation-guide]: ../../pr-comment-resolution/tools/full-automation-guide.md "Full Automation Guide"
[START_HERE]: ../../pr-comment-resolution/START_HERE.md "Start Here: LLM-Driven PR Resolution"
