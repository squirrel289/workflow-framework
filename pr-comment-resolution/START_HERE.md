
# Start Here: LLM-Driven PR Resolution

**→ For the default, non-interactive workflow, see [[sequential-workflow]].**

**→ Framework Guide:** See [[FRAMEWORK]] to understand how this workflow fits into the larger automation framework.

## Quick Start Decision

```
Using LLM to resolve PR comments?
│
├─ Single PR? → Use [[sequential-workflow]] (default, non-interactive)
├─ Single PR with 10+ comments? → Use [[parallel-workflow]] (BEST)
├─ Multiple PRs? → Just run workflow N times per PR
├─ Iterative/exploratory? → Use [[interactive-workflow]]
└─ Want full automation example? → See [[full-automation-guide]]

Implementation help? → [[parallel-execution-techniques]]
```

## For Single PR End-to-End

**Recommended:** Use [[sequential-workflow]] for the default, non-interactive, step-by-step process.

If you need to load phases individually, follow the instructions in that file.

## For Parallel Processing (Multiple PRs)

**Load once per agent:**
```
Agent 1 (PR #123): [[01-research-analysis]]
Agent 2 (PR #124): [[01-research-analysis]]  ← Same file, different PR
Agent 3 (PR #125): [[01-research-analysis]]
```

**Benefits:**
- Each agent loads only 2KB (~500 tokens)
- Total: 1,500 tokens for 3 PRs


**Files to load per phase:**
1. Research: [[01-research-analysis]] + [[gh-pr-review-guide]]
2. Planning: [[02-planning]] (already has context from phase 1)
3. Implementation: [[03-implementation]]
4. Resolution: [[04-resolution-verification]] + [[TECHNICAL_REFERENCE]]

## Understanding Context Reuse

### Same LLM Context (Stateful Session)

✅ **Load incrementally, keep all context:**
```
Step 1: Load Phase 1 research (~500 tokens)
        ↓ Context: Research phase + PR data
Step 2: Execute Phase 1
        ↓ Keep context, add findings
Step 3: Load Phase 2 planning (~500 tokens, add to context)
        ↓ Context: Phases 1-2 + PR data + findings
Step 4: Execute Phase 2
        ↓ Keep context, add plan
Step 5: Load Phase 3 implementation (~500 tokens, add to context)
        ↓ Continue with full context
```

**Total tokens:** ~2,000 per phase × 4 phases

### Different LLM Contexts (Sub-agents)

✅ **Each agent loads only its phase:**

```
Sub-agent A (PR #123): [[01-research-analysis]] (~500 tokens)
Sub-agent B (PR #123): [[02-planning]] (~500 tokens)
Sub-agent C (PR #123): [[03-implementation]] (~700 tokens)
```

**Total tokens:** ~8,800 across all agents
**Benefit:** Parallel execution, isolated failure domains

## File Loading Strategies by Use Case


### Use Case 1: Single PR, One Agent, Start to Finish
**Load:** [[sequential-workflow]]
**Why:** Minimal, focused, step-by-step instructions for default workflow
**Cost:** ~2,000 tokens (phases loaded as needed)

### Use Case 2: 10 PRs, Sequential Processing
**Load:** [[sequential-workflow]] for each PR (or load phases as needed)
**Why:** Minimal context per PR, easy to parallelize if needed
**Cost:** ~2,000 tokens per PR

### Use Case 3: 10 PRs, Parallel Agents
**Load per agent:** [[01-research-analysis]]
**Why:** Each agent independent, fault-tolerant
**Cost:** 10 × 500 = 5,000 tokens (but parallel!)

### Use Case 4: Large PR, Intra-PR Parallelization (BEST for 10+ comments)
**Coordinator Agent:**
- Load: [[01-research-analysis]] (500 tokens)
- Load: [[02-planning]] (600 tokens)
- Load: [[04-resolution-verification]] (500 tokens)

**Worker Agents (3 agents):**
- Each loads: [[03-implementation]] (700 tokens)
- Each processes: Assigned subset of comments

**Why:** Parallelize implementation, fastest completion
**Cost:** 1,600 (coordinator) + 2,100 (workers) = **3,700 tokens**
**Time:** ~4x faster than sequential
**See:** [[parallel-workflow]]

### Use Case 5: Exploratory/Debugging
**Load as needed:**
- Start: [[01-research-analysis]]
- Stuck on categorization? Add: [[02-planning]]
- Need automation? Add: [automated-pr-resolution.sh](./templates/shell-scripts/automated-pr-resolution.sh)

**Why:** Pay only for what you need
**Cost:** Variable, typically 500-1,500 tokens

## Can I Omit Repeat Files?

### In Same Context (Stateful)?
**Yes!** Once loaded, never reload unless context is lost.

```bash
# First PR in session
Load: Nothing (0 tokens) ← Reuse existing context!
Process PR #124 using existing workflow knowledge

# Second PR in SAME session
Load: Nothing (0 tokens) ← Reuse existing context!
Process PR #124 using existing workflow knowledge
```

### With Sub-agents (Parallel)?
**No**, each agent needs its own context.

```bash
# Each agent is independent
Agent 1: Load phases/01-research-analysis.md (500 tokens)
Agent 2: Load phases/01-research-analysis.md (500 tokens) ← Must load again
Agent 3: Load phases/02-planning-categorization.md (600 tokens)
```

**Exception:** If your LLM platform supports shared context/memory, you can share base files.

## DRY Principle: Best of Both Worlds

### Source of Truth: Modular Files
- Maintain `phases/*.md`, `tools/*.md`, `patterns/*.md`
- Easy to update specific sections
- Version control friendly (small diffs)



## Next Steps

1. **First time user?** Use [[sequential-workflow]] for the default workflow
2. **Experienced user?** Jump to specific phase or pattern file
3. **Building automation?** Start with [[shell-scripts]] examples
4. **Need tools reference?** See [[QUICK_REFERENCE]] for commands

## File Decision Matrix

| Your Situation | Files to Load | Token Cost | Time |
|---------------|---------------|------------|------|
| **Single PR with 10+ comments** | **Intra-PR parallel** | **~3,700** | **Fastest** |
| Single PR (default) | [[sequential-workflow]] | ~2,000 | Moderate |
| Multiple PRs, same agent | [[sequential-workflow]] per PR | ~2,000 each | Moderate |
| Multiple PRs, parallel agents | [[01-research-analysis]] per agent | ~500 each | Fast |
| Just researching | [[01-research-analysis]] | ~500 | Quick |
| Just implementing | [[03-implementation]] | ~700 | Quick |
| Need automation | [[full-automation-guide]] | varies | - |
| Learning tools | [[gh-pr-review-guide]] | ~600 | - |

---

**TL;DR:** Use [[sequential-workflow]] for the default workflow. Use individual phase files for parallel/iterative work. Context reuse wins big in stateful sessions.

---

[sequential-workflow]: ../_shared/patterns/sequential-workflow.md "Sequential PR Resolution Workflow"
[FRAMEWORK]: ../FRAMEWORK.md "Workflow Automation Framework"
[parallel-workflow]: ../_shared/patterns/parallel-workflow.md "Intra-PR Parallel Workflow"


[full-automation-guide]: tools/full-automation-guide.md "Full Automation Guide"


[01-research-analysis]: ../_shared/phases/01-research-analysis.md "Phase 1: Research & Analysis"
[02-planning]: ../_shared/phases/02-planning.md "Phase 2: Planning"
[03-implementation]: ../_shared/phases/03-implementation.md "Phase 3: Implementation"
[04-resolution-verification]: ../_shared/phases/04-resolution-verification.md "Phase 4: Resolution & Verification"
[gh-pr-review-guide]: tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"
[TECHNICAL_REFERENCE]: ../_shared/tools/TECHNICAL_REFERENCE.md "Technical Reference"


[shell-scripts]: templates/shell-scripts/ "Shell Scripts"
[QUICK_REFERENCE]: QUICK_REFERENCE.md "PR Resolution Quick Reference"
