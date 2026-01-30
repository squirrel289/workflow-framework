# PR Comment Resolution Workflow

A systematic, modular approach for resolving all comments, to-dos, and issues in pull requests. Optimized for LLM agents, automation scripts, and human developers.

## Philosophy

Follow the research/plan/implement pattern for consistent, reproducible PR resolution across any IDE, version control platform, and LLM assistant.

## Quick Start

**→ Using LLM to resolve PR? [[START_HERE]] ← Complete LLM loading guide**

**→ Need commands/cheat sheet? [[QUICK_REFERENCE]]**

### Approach

This workflow is part of the [[FRAMEWORK]]. It leverages:

- **Shared phases** (`_shared/phases/`) - Research, planning, implementation, verification
- **Shared patterns** (`_shared/patterns/`) - Parallel execution, interactive workflows
- **Shared tools** (`_shared/tools/`) - GitHub APIs, execution techniques, technical reference
- **Workflow-specific tools** (`tools/`) - gh-pr-review integration, multi-PR orchestration

See [[FRAMEWORK]] for how this structure grows with new workflows.

## Quick Start

### For LLM Agents
1. Read [[START_HERE]] - Complete loading guide
2. Load phases progressively: [[01-research-analysis]] → [[02-planning]] → [[03-implementation]] → [[04-resolution-verification]]
3. Reference [[gh-pr-review-guide]] for data gathering
4. For large PRs (10+ comments): Use [[parallel-workflow]]
5. For full end-to-end automation examples: See [[full-automation-guide]]

### For Automation/CI
1. Use [[shell-scripts]]
2. Reference [[TECHNICAL_REFERENCE]]
3. Follow [[multi-pr-orchestration]] for batch operations
4. See [[full-automation-guide]] for complete implementation examples

### For Humans
1. Read this [[README]]
2. Jump to [[phases]] as needed
3. Use [[interactive-workflow]]

## Workflow Structure

### Four-Phase Approach (Shared)

1. **Research & Analysis** - Gather PR context, identify unresolved threads ([[01-research-analysis]])
2. **Planning** - Group items, identify dependencies, prioritize ([[02-planning]])
3. **Implementation** - Make changes, run tests, commit ([[03-implementation]])
4. **Resolution & Verification** - Mark threads resolved, verify ([[04-resolution-verification]])

### Tools

- **[[gh-pr-review-guide]]** (Recommended) - LLM-optimized, deterministic JSON output
- **[[gh-review-conductor-guide]]** - Interactive TUI for manual workflows
- **[[github-apis]]** - Direct REST/GraphQL reference

### Patterns

- **[[parallel-workflow]]** - Resolve multiple independent comments simultaneously
- **[[interactive-workflow]]** - Human-driven review processes

### Templates

- **[[shell-scripts]]** - Ready-to-use automation scripts
- **[[prompts]]** - Reusable LLM prompt templates

## Why Modular?

**For LLMs:**
- Load only relevant files (~500-2,000 tokens per phase)
- Parallel agents: Each loads different phases
- Context reuse: Load once, use for multiple PRs
- See [[START_HERE]] for detailed loading strategies

**For Automation:**
- Each phase = separate CI/CD step
- Scripts reference only needed documentation
- Test and version independently

**For Humans:**
- Find what you need quickly
- Progressive learning (start with Phase 1)
- Reference specific tools/patterns

## Usage Examples

### LLM Agent: Phase 1 Only
```bash
# Agent loads only research phase + tool guide
cat phases/01-research-analysis.md tools/gh-pr-review-guide.md | llm-agent
```

### CI/CD: Automated Resolution
```bash
# Run complete automation script
./templates/shell-scripts/automated-pr-resolution.sh 42
```

### Human: Check Unresolved Comments
```bash
# Follow instructions from research phase
gh pr-review review view -R owner/repo --pr 42 --unresolved
```

## Contributing

This workflow is IDE-agnostic, LLM-agnostic, and platform-agnostic. Contributions welcome for:
- Additional tool integrations (GitLab, Gitea, Bitbucket)
- New automation patterns
- Improved prompt templates
- Alternative shell script examples
---

[START_HERE]: START_HERE.md "Start Here: LLM-Driven PR Resolution"
[QUICK_REFERENCE]: QUICK_REFERENCE.md "PR Resolution Quick Reference"
[FRAMEWORK]: ../FRAMEWORK.md "Workflow Automation Framework"
[README]: README.md "PR Comment Resolution Workflow"
[01-research-analysis]: ../_shared/phases/01-research-analysis.md "Phase 1: Research & Analysis"
[02-planning]: ../_shared/phases/02-planning.md "Phase 2: Planning"
[03-implementation]: ../_shared/phases/03-implementation.md "Phase 3: Implementation"
[04-resolution-verification]: ../_shared/phases/04-resolution-verification.md "Phase 4: Resolution & Verification"
[parallel-workflow]: ../_shared/patterns/parallel-workflow.md "Intra-PR Parallel Workflow"
[interactive-workflow]: ../_shared/patterns/interactive-workflow.md "Interactive Workflow Pattern"
[gh-pr-review-guide]: tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"
[gh-review-conductor-guide]: tools/gh-review-conductor-guide.md "gh-review-conductor Tool Guide"
[github-apis]: ../_shared/tools/github-apis.md "GitHub APIs Reference"
[TECHNICAL_REFERENCE]: ../_shared/tools/TECHNICAL_REFERENCE.md "Technical Reference"
[multi-pr-orchestration]: tools/multi-pr-orchestration.md "Multi-PR Orchestration Guide"
[full-automation-guide]: tools/full-automation-guide.md "Full Automation Guide"
[shell-scripts]: templates/shell-scripts/ "Shell Scripts"
[prompts]: templates/prompts/ "Prompt Templates"
[phases]: ../_shared/phases/ "Shared Phases"