# Intra-PR Parallel Workflow

**Pattern:** Parallelize work WITHIN a single PR across multiple agents for maximum efficiency and speed.

## Use When

- Large PR with 10+ comments
- Comments touch independent areas of codebase
- Time-critical resolution needed
- Different complexity levels per comment (simple vs complex)
- Team wants to divide and conquer single PR

## Workflow Architecture

```
                    Single PR with 15 comments
                             │
                             │                 
          Phase 1: Research  │  (Sequential, 1 agent)
                             │
          Phase 2: Planning  │  (Sequential, 1 agent)
                             │
              ┌─────────┬────┴────┬─────────┐
              │         │         │         │
        Phase 3: Implementation (Parallel, N agents)
        Agent A     Agent B    Agent C    Agent D
        cmt 1-5    cmt 6-10   cmt 11-13  cmt 14-15
              │         │         │         │
              └─────────┴─────────┴─────────┘
                             │
        Phase 4: Resolution  │  (Sequential, 1 agent)
                             │
                          Done ✓
```

## Agent Orchestration

### Coordinator Agent (Agent 1)
**Responsibilities:**
- Phase 1: Research & Analysis (gather all comments)
- Phase 2: Planning & Categorization (create implementation plan)
- Phase 4: Resolution & Verification (aggregate and resolve)

**Context:** Maintains state across entire PR lifecycle

### Worker Agents (Agents 2-N)
**Responsibilities:**
- Phase 3: Implementation only
- Handle assigned subset of comments
- Return changesets/fixes to coordinator

**Context:** Independent, loaded only for implementation phase

## Token Efficiency Analysis

### This Pattern (Intra-PR Parallel)
```
Agent 1 (Coordinator):
  - Load phases/01-research-analysis.md       500 tokens
  - Load phases/02-planning.md                600 tokens
  - Load phases/04-resolution-verification.md 500 tokens
  Subtotal: 1,600 tokens (persistent context)

Agent 2 (Worker):
  - Load phases/03-implementation.md          700 tokens
  (Processes comments 1-5)

Agent 3 (Worker):
  - Load phases/03-implementation.md          700 tokens
  (Processes comments 6-10)

Agent 4 (Worker):
  - Load phases/03-implementation.md          700 tokens
  (Processes comments 11-15)

Total: 1,600 + (700 × 3) = 3,700 tokens
```

### Alternative: Single Agent + sequential-workflow.md
```
Agent 1:
  - Load sequential-workflow.md               ~2,000 tokens
  - Process all comments sequentially

Total: ~2,000 tokens
```

### Alternative: Full Modular Loading
```
Agent 1:
  - Load phases/01-research-analysis.md       500 tokens
  - Load phases/02-planning.md                600 tokens
  - Load phases/03-implementation.md          700 tokens
  - Load phases/04-resolution-verification.md 500 tokens

Total: 2,300 tokens (but sequential processing)
```

## Comparison Summary

| Approach | Tokens | Time (wall clock) | Best For |
|----------|--------|-------------------|----------|
| **Intra-PR Parallel** | **3,700** | **Fastest** | **Large PRs, 10+ comments** |
| Single + sequential-workflow | ~2,000 | Moderate | Simple PRs, 1-5 comments |
| Single + Modular | 2,300 | Slow | Learning, debugging |

**Winner:** Intra-PR parallel for 53% token savings AND fastest completion!

## Implementation Example

### Step 1: Coordinator Researches (Agent 1)

```bash
# Agent 1 loads research phase
echo "Agent 1: Research phase"
THREADS=$(gh pr-review unresolved --pr 123 --json)
echo "$THREADS" > pr123-threads.json
```

**Loaded:** `phases/01-research-analysis.md` (500 tokens)
**Output:** `pr123-threads.json` with all 15 comment threads

### Step 2: Coordinator Plans (Agent 1, same context)

```bash
# Agent 1 already has context, loads planning phase
echo "Agent 1: Planning phase"
cat pr123-threads.json | categorize-and-plan > pr123-plan.json
```

**Loaded:** `phases/02-planning.md` (600 tokens, adds to existing context)
**Output:** `pr123-plan.json` with implementation assignments
```json
{
  "simple": ["PRRT_1", "PRRT_2", "PRRT_8"],
  "moderate": ["PRRT_3", "PRRT_4", "PRRT_5", "PRRT_9", "PRRT_10"],
  "complex": ["PRRT_6", "PRRT_7"],
  "assignments": {
    "agent_2": ["PRRT_1", "PRRT_2", "PRRT_3", "PRRT_4", "PRRT_5"],
    "agent_3": ["PRRT_8", "PRRT_9", "PRRT_10"],
    "agent_4": ["PRRT_6", "PRRT_7"]
  }
}
```

### Step 3: Workers Implement in Parallel (Agents 2-4)

```bash
# Launch parallel workers
for agent in agent_2 agent_3 agent_4; do
  (
    # Each worker is independent, loads implementation phase
    echo "$agent: Implementation phase"
    ASSIGNMENT=$(jq -r ".assignments.$agent[]" pr123-plan.json)
    
    for thread_id in $ASSIGNMENT; do
      # Implement fix for this thread
      implement-fix --thread "$thread_id" --output "fixes/$thread_id.patch"
    done
  ) &
done

wait
echo "All workers complete"
```

**Loaded per worker:** `phases/03-implementation.md` (700 tokens each)
**Output:** Patch files for each assigned comment

### Step 4: Coordinator Resolves (Agent 1, same context)

```bash
# Agent 1 aggregates results
echo "Agent 1: Resolution phase"

# Apply all patches
for patch in fixes/*.patch; do
  git apply "$patch"
done

# Resolve all threads
jq -r '.threads[].id' pr123-threads.json | while read thread_id; do
  gh pr-review resolve --thread-id "$thread_id" --comment "Fixed ✓"
done

# Create approval review
gh pr-review create --pr 123 --approve --body "All 15 comments resolved"
```

**Loaded:** `phases/04-resolution-verification.md` (500 tokens, adds to existing context)
**Output:** PR #123 fully resolved with approval review

## Optimization Strategies

### 1. Load Balancing

Assign comments by complexity/time:
```json
{
  "agent_2": ["PRRT_simple_1", "PRRT_simple_2", "PRRT_moderate_1"],
  "agent_3": ["PRRT_moderate_2", "PRRT_moderate_3"],
  "agent_4": ["PRRT_complex_1"]  // One complex = same time as 5 simple
}
```

### 2. Dependency Detection

Some comments depend on others:
```json
{
  "phase_1": {
    "agent_2": ["PRRT_1"]  // Must complete first
  },
  "phase_2": {
    "agent_3": ["PRRT_2"],  // Depends on PRRT_1
    "agent_4": ["PRRT_3"]   // Independent
  }
}
```

### 3. Failure Isolation

If Agent 3 fails, others continue:
```bash
# Agent 3 fails on PRRT_9
echo "Agent 3 failed, reassigning PRRT_9 to Agent 5"
# Agent 5 picks up failed work
agent_5 implement-fix --thread PRRT_9
```

### 4. Context Sharing (Advanced)

If your LLM platform supports shared context/memory:
```
Shared Context Pool:
  - phases/01-research-analysis.md (loaded once)
  - phases/02-planning.md (loaded once)
  - pr123-threads.json (shared data)

Agent 2: Access shared context + load phases/03-implementation.md
Agent 3: Access shared context + load phases/03-implementation.md
Agent 4: Access shared context + load phases/03-implementation.md

Token savings: ~1,100 tokens (don't reload research/planning for each worker)
```

## Decision Tree

```
Single PR needs resolution?
│
├─ 1-5 comments? → Use [[sequential-workflow|Sequential PR Resolution Workflow]] (default)
│
├─ 6-10 comments? → Consider intra-PR parallel (marginal gains)
│
└─ 10+ comments? → USE INTRA-PR PARALLEL (big wins)
  │
  ├─ Comments independent? → Full parallelization
  │
  ├─ Some dependencies? → Phase/stage parallelization
  │
  └─ All dependent? → Sequential modular (still better than monolithic)
```

## Real-World Example

**Scenario:** PR #123 with 25 comments across 10 files

### Sequential (sequential-workflow.md)
- Time: ~60 minutes (25 comments × 2-3 min each)
- Tokens: ~2,000
- Agents: 1

### Intra-PR Parallel (This Pattern)
- Time: ~15 minutes (5 agents × 5 comments each)
- Tokens: 1,600 (coordinator) + 3,500 (5 workers × 700) = 5,100
- Agents: 6
- **Speedup: 4x faster, 27% fewer tokens**

## Scaling: Multiple PRs in Parallel

To process multiple PRs simultaneously, run this workflow N times in parallel.

**Architecture:** Each PR gets its own coordinator + workers, all PRs run independently.

**Complexity:** Orchestration (gating, verification, failure handling, resource limits).

**For complete patterns, scripts, and gating strategies, see:**  
👉 [[multi-pr-orchestration]]

**Quick examples:**

```bash
# Independent verification (recommended)
for pr in 101 102 103; do
  process_pr_parallel "$pr" &  # Each PR uses this workflow
done
wait

# Batch verification (integration testing)
# Process all, then verify integration, then approve batch

# Progressive rollout (priority order)
# Critical PRs first, then others
```

**Performance:** 3 PRs with 20 comments each:
- Sequential: 180 min, 21,000 tokens
- Multi-PR + Parallel: 15 min, 15,300 tokens
- **Result: 12x faster, 27% fewer tokens**

**Key decisions:** Independent vs batch verification? Continue-on-error vs fail-fast? Resource limits?

**See [[multi-pr-orchestration]] for complete guide.**

## Tools & Commands

### Coordinator Agent Commands

```bash
# Research
gh pr-review unresolved --pr <pr_number> --json > threads.json

# Planning
cat threads.json | jq -r '.threads[] | "\(.id),\(.body)"' | \
  categorize-complexity > plan.json

# Resolution
cat plan.json | jq -r '.assignments[] | .[]' | \
  xargs -I {} gh pr-review resolve --thread-id {}
```

### Worker Agent Commands

```bash
# Each worker receives:
THREADS='["PRRT_1", "PRRT_2", "PRRT_3"]'

# Implement each
echo "$THREADS" | jq -r '.[]' | while read thread_id; do
  # Load thread details
  THREAD_DATA=$(jq --arg id "$thread_id" \
    '.threads[] | select(.id == $id)' threads.json)
  
  # Implement fix
  implement-fix --thread "$THREAD_DATA" --output "fix-$thread_id.patch"
done
```

## Benefits

✅ **Speed:** N times faster for N independent comments  
✅ **Efficiency:** 27-47% fewer tokens than monolithic workflows  
✅ **Scalability:** Handles large PRs (20-50+ comments) gracefully  
✅ **Fault tolerance:** Worker failure doesn't block entire PR  
✅ **Resource optimization:** Only load what each agent needs  
✅ **Flexibility:** Can add/remove workers dynamically  

## Drawbacks

⚠️ **Complexity:** Requires orchestration logic  
⚠️ **Coordination overhead:** Managing agent assignments and results  
⚠️ **Merge conflicts:** Multiple agents editing same files (rare)  
⚠️ **Infrastructure:** Need platform supporting parallel agents  

## Recommended For

- **Large PRs:** 10+ comments
- **Time-sensitive:** Need fast resolution
- **Team workflows:** Multiple engineers/agents available
- **Production systems:** Where downtime/delays are costly
- **Complex repositories:** Large codebases with independent modules

**Not Recommended For:**
- Small PRs (1-5 comments) - overhead not worth it
- Learning/exploration - harder to debug
- Simple fixes - sequential-workflow.md is simpler
- Highly coupled changes - dependencies complicate parallelization

---

## Implementation Reference

For detailed bash/Python parallel execution code, see: [[parallel-execution-techniques]]

**TL;DR:** For large PRs, split implementation across multiple agents while coordinator handles research/planning/resolution. Saves tokens AND time.

---

[multi-pr-orchestration]: ../../pr-comment-resolution/tools/multi-pr-orchestration.md "Multi-PR Orchestration Guide"
[parallel-execution-techniques]: ../tools/parallel-execution-techniques.md "Parallel Execution Techniques"
