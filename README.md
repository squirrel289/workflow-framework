# Workflow Automation Toolkit

A modular framework for designing reproducible, LLM-friendly automation workflows. Patterns and abstractions emerge as more workflows are added.

## Quick Navigation

- **[FRAMEWORK.md](FRAMEWORK.md)** - How to build new workflows on this framework
- **[pr-comment-resolution/](pr-comment-resolution/)** - First workflow implementation (example)
- **[_shared/](\_shared/)** - Shared components across all workflows

## What's Included

### Shared Framework (`_shared/`)

Reusable components available to all workflows:

- **[Phases](\_shared/phases/)** - Generic workflow phases (research, planning, implementation, verification)
- **[Patterns](\_shared/patterns/)** - Orchestration patterns (parallel, interactive)
- **[Tools](\_shared/tools/)** - Technical references (APIs, execution techniques, consolidated reference)

### First Workflow: PR Comment Resolution (`pr-comment-resolution/`)

Complete, production-ready automation for resolving PR comments:

- **[README.md](pr-comment-resolution/README.md)** - Workflow overview
- **[START_HERE.md](pr-comment-resolution/START_HERE.md)** - LLM loading guide
- **[QUICK_REFERENCE.md](pr-comment-resolution/QUICK_REFERENCE.md)** - Command cheat sheet
- **[tools/](pr-comment-resolution/tools/)** - Workflow-specific tools (gh-pr-review, multi-PR orchestration)
- **[templates/](pr-comment-resolution/templates/)** - Scripts and LLM prompts

## Getting Started

### Using the PR Comment Resolution Workflow

```bash
cd pr-comment-resolution
cat START_HERE.md  # Choose your approach (parallel, stateful, interactive)
```

### Building a New Workflow

```bash
1. Read FRAMEWORK.md
2. Create workflows/my-workflow/
3. Link to _shared/ components
4. Document workflow-specific tools in tools/
5. Extract generalizable patterns back to _shared/
```

## Philosophy

**Modular by design, monolithic when needed:**
- Shared components prevent duplication across workflows
- Each workflow is self-contained and self-documenting
- New patterns emerge as workflows are added
- No upfront architecture—structure grows with reality

**LLM-friendly:**
- Load only relevant files per phase
- Reuse context across multiple PRs
- Progressive context loading for token efficiency
- Clear, structured documentation

## Workflow Gallery

| Workflow | Status | Purpose |
|----------|--------|---------|
| [PR Comment Resolution](pr-comment-resolution/) | ✅ Production | Resolve all comments/TODOs in pull requests |
| Sprint Planning | 📋 Template | Plan sprints, estimate capacity |
| Backlog Grooming | 📋 Template | Prioritize, decompose, refine issues |
| Release Candidate Assembly | 📋 Template | Validate, document, prepare releases |

(More workflows added as patterns emerge.)

## Structure at a Glance

```
workflows/
├── FRAMEWORK.md                 ← Start here for new workflows
├── README.md                    ← This file
├── _shared/                     ← Reusable components
│   ├── phases/                  (01-research, 02-planning, 03-implementation, 04-resolution)
│   ├── patterns/                (parallel-workflow, interactive)
│   └── tools/                   (github-apis, parallel-execution-techniques, reference)
└── pr-comment-resolution/       ← Example: First workflow
    ├── README.md
    ├── START_HERE.md
    ├── QUICK_REFERENCE.md
    ├── tools/                   (gh-pr-review, multi-pr-orchestration)
    ├── templates/               (scripts, prompts)
    └── scripts/
```

---

**Next Steps:**
- Using PR Comment Resolution? → [START_HERE.md](pr-comment-resolution/START_HERE.md)
- Building a new workflow? → [FRAMEWORK.md](FRAMEWORK.md)
- Want technical details? → [_shared/tools/TECHNICAL_REFERENCE.md](\_shared/tools/TECHNICAL_REFERENCE.md)
