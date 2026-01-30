# Workflow Automation Framework

A modular framework for designing reproducible, LLM-friendly automation workflows. Each workflow can leverage shared phases, patterns, and tools while maintaining workflow-specific documentation and implementation details.

## Structure

```
workflows/
├── FRAMEWORK.md                 (this file)
├── _shared/                     (framework components shared across workflows)
│   ├── phases/                  (generic workflow phases)
│   │   ├── 01-research-analysis.md
│   │   ├── 02-planning.md
│   │   ├── 03-implementation.md
│   │   └── 04-resolution-verification.md
│   ├── patterns/                (workflow orchestration patterns)
│   │   ├── parallel-workflow.md        (multiple agents, concurrent execution)
│   │   └── interactive-workflow.md     (human-in-the-loop gates)
│   └── tools/                   (shared technical references)
│       ├── github-apis.md
│       ├── parallel-execution-techniques.md
│       └── TECHNICAL_REFERENCE.md
└── <workflow-name>/             (workflow implementation)
    ├── README.md                (workflow overview)
    ├── START_HERE.md            (LLM loading guide)
    ├── QUICK_REFERENCE.md       (command cheat sheet)
    ├── tools/                   (workflow-specific tools & references)
    │   └── full-automation-guide.md    (end-to-end automation implementation)
    ├── templates/               (scripts, prompts, examples)
    └── scripts/                 (automation scripts)
```

## Creating a New Workflow

### 1. Assess Phase Applicability

Not all workflows use all phases. Examine your workflow against the generic phases:

- **Phase 1 (Research):** Gather requirements, analyze state, identify constraints
- **Phase 2 (Planning):** Design approach, identify tasks, estimate complexity
- **Phase 3 (Implementation):** Execute tasks, build artifacts, iterate
- **Phase 4 (Resolution/Verification):** Validate outcomes, verify constraints, wrap up

**Example: Sprint Planning Workflow**
- Phase 1: ✅ Research (analyze backlog, team capacity)
- Phase 2: ✅ Planning (prioritize, assign sprints)
- Phase 3: ✅ Implementation (create sprint backlog, add items)
- Phase 4: ✅ Verification (validate sprint readiness)

**Example: Automated Code Review**
- Phase 1: ✅ Research (fetch PR, analyze changes)
- Phase 2: ✅ Planning (identify review focus areas)
- Phase 3: ❌ Implementation (not applicable—no artifact building)
- Phase 4: ✅ Verification (compile review, post comments)

### 2. Create Workflow Directory

```bash
mkdir -p workflows/<workflow-name>/{tools,templates,scripts}
```

### 3. Create Entry Points

Copy template entry points from [[pr-comment-resolution/]]:

- [[README]] - Workflow overview, philosophy, when to use
- [[START_HERE]] - LLM loading guide, context reuse patterns
- [[QUICK_REFERENCE]] - Commands, one-liners, decision trees

Update references to point to relevant shared phases and patterns.

### 4. Add Workflow-Specific Tools

Create `tools/*.md` for workflow-specific technical references:

- `service-integration.md` (if integrating with external services)
- `orchestration-guide.md` (if managing multi-agent workflows)
- `error-handling.md` (workflow-specific error strategies)

Reference shared tools from [[tools/]] in your documentation.

### 5. Compose Patterns

Declare which patterns apply to your workflow:

- **Parallel workflow:** When tasks within workflow can run concurrently
- **Interactive workflow:** When human feedback loops are needed

Point users to [[patterns/]] for implementation details.

### 6. Document Implementation

Create workflow-specific scripts and templates:

- `scripts/orchestrate.sh` - Main automation entry point
- `templates/prompts/*.md` - LLM prompts for each phase
- `templates/shell-scripts/*.sh` - Utility scripts

### 7. Update This Guide

If your workflow introduces new patterns or generalizable tools:

1. Extract to [[patterns/]] or [[tools/]] if applicable
2. Reference from [[_shared/]] in your workflow
3. Update this [[FRAMEWORK]] with the new component

## Shared Components

### Phases

The generic phases ([[phases/]]) apply to most workflows:

1. **Research & Analysis** - Understand the problem space
2. **Planning** - Design the approach
3. **Implementation** - Execute the work
4. **Resolution & Verification** - Validate and wrap up

Each workflow documents which phases apply and how they're customized.

### Patterns

Two core orchestration patterns in [[patterns/]]:

- **Parallel Workflow:** Coordinator + worker agents, suited for large tasks with independent sub-tasks
- **Interactive Workflow:** Human-in-the-loop validation and decision-making

(Note: "Full automation" is not a pattern—it's the default when you follow phases sequentially. See workflow-specific [[temple/tools/full-automation-guide]] for implementation examples.)

### Tools

Shared technical references in [[tools]]:

- **GitHub APIs:** GraphQL/REST endpoints, auth, common patterns
- **Parallel Execution Techniques:** Bash/Python concurrency patterns
- **TECHNICAL_REFERENCE:** Consolidated tooling guide

Workflow-specific tools (in each workflow's `tools/` directory):
- **Full Automation Guide:** End-to-end implementation examples
- **Tool Integration Guides:** Service-specific integrations
- **Multi-Workflow Orchestration:** Multi-PR/multi-workflow coordination

## Workflow Examples

### Example 1: PR Comment Resolution

**Location:** [[pr-comment-resolution/]]

**Applies:**
- All 4 phases (research PR, plan resolution, implement fixes, verify)
- Parallel workflow pattern (coordinator reviews PR, workers implement fixes)
- Default sequential execution (agent follows phases 1→2→3→4)

**Workflow-Specific Tools:**
- [[gh-pr-review-guide]] - GitHub CLI extension for fetching PR data
- [[pr-comment-resolution/multi-pr-orchestration]] - Managing resolution across multiple PRs
- [[full-automation-guide]] - End-to-end implementation examples with bash/Python code

### Example 2: Sprint Planning (Hypothetical)

**Would Apply:**
- Phases 1, 2, 4 (research capacity, plan sprint, verify readiness)
- Interactive workflow pattern (PMs confirm priorities, leads confirm capacity)
- Parallel workflow pattern (analyze team capacity, groom backlog concurrently)

**Would Add:**
- `jira-integration.md` - Jira API reference
- `capacity-estimation.md` - Velocity calculations
- `capacity-analysis.md` - LLM prompt for team analysis

## Guidelines

### ✅ Do

- Reuse shared phases and patterns
- Reference shared tools from your workflow
- Document workflow-specific tooling in `tools/`
- Keep entry points (`README`, `START_HERE`, `QUICK_REFERENCE`) focused and concise
- Update FRAMEWORK.md when introducing new shared components

### ❌ Don't

- Duplicate shared phases or patterns
- Create workflow-specific versions of generic tools
- Add tools to [[_shared/]] unless they apply to 2+ workflows
- Import entire shared files into workflow docs (link instead)

## Decision Tree: When to Extract to [[_shared/]]

```
Is this component used by 2+ workflows?
├─ No  → Keep in workflow-specific tools/
└─ Yes → Can other workflows adopt it as-is?
        ├─ No  → Keep in workflow tools/ and document
        └─ Yes → Extract to _shared/, link from workflow
```

## Evolution

As new workflows are added:

1. **Phase 5**: A new workflow discovers missing phases? Add to [[phases/]] for workflow 6
2. **Pattern 4**: Multiple workflows need approval gates? Generalize pattern and add to [[patterns/]]
3. **Tool Growth**: Consolidate related tools into specialized references

This framework grows with usage, not in anticipation of it.

## Quick Reference

**Adding a new workflow?**
1. Create directory: `mkdir -p workflows/my-workflow/{tools,templates,scripts}`
2. Copy entry points from [[pr-comment-resolution/]]
3. Link to relevant shared [[phases/]], [[.md]], [[tools/]]
4. Document workflow-specific implementation
5. Extract generalizable components to [[_shared/]] if applicable

**Want to see an example?** → [[pr-comment-resolution/]]

---

[FRAMEWORK]: ./FRAMEWORK.md "Workflow Automation Framework"
[README]: ./README.md "Workflow Overview"
[START_HERE]: ./pr-comment-resolution/START_HERE.md "LLM Loading Guide"
[QUICK_REFERENCE]: ./pr-comment-resolution/QUICK_REFERENCE.md "Command Cheat Sheet"
[full-automation-guide]: ./pr-comment-resolution/tools/full-automation-guide.md "Full Automation Guide"

[patterns/]: ./_shared/patterns/ "Patterns Directory"
[tools/]: ./_shared/tools/ "Tools Directory"
[_shared/]: ./_shared/ "Shared Components"
[phases/]: ./_shared/phases/ "Phases Directory"
[pr-comment-resolution/]: ./pr-comment-resolution/ "PR Comment Resolution Workflow Directory"

[gh-pr-review-guide]: ./pr-comment-resolution/tools/gh-pr-review-guide.md "GitHub PR Review Guide"

[temple/tools/full-automation-guide]: ../temple/tools/full-automation-guide.md "tools/full-automation-guide"

[pr-comment-resolution/multi-pr-orchestration]: ../temple/workflows/pr-comment-resolution/multi-pr-orchestration.md "workflows/pr-comment-resolution/multi-pr-orchestration"