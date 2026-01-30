# Multi-PR Orchestration Guide

Patterns and scripts for processing multiple PRs simultaneously using the parallel workflow pattern.

**When to load this:** Only when processing 2+ PRs at the same time. For single PR parallelization, see [[parallel-workflow]].

---

## Architecture Pattern

```
Main Orchestrator
├─ PR #101 → Coordinator 1A + Workers [2A, 3A, 4A, 5A]
├─ PR #102 → Coordinator 1B + Workers [2B, 3B, 4B]
└─ PR #103 → Coordinator 1C + Workers [2C, 3C, 4C, 5C]

Each PR runs independently through all 4 phases
```

**Key insight:** Each PR uses the parallel workflow pattern internally. Multi-PR orchestration is about running N workflows in parallel with proper gating and verification.

---

## Complete Orchestration Script

```bash
#!/bin/bash
# parallel-prs.sh - Process multiple PRs in parallel

set -euo pipefail

PR_NUMBERS=(101 102 103)
MAX_CONCURRENT=3

# Function to process single PR using parallel workflow
process_pr_parallel() {
  local pr=$1
  echo "Starting PR #$pr..."
  
  # Phase 1: Research (coordinator)
  THREADS=$(gh pr-review unresolved --pr "$pr" --json)
  echo "$THREADS" > "pr${pr}-threads.json"
  
  # Phase 2: Planning (coordinator)
  cat "pr${pr}-threads.json" | categorize-and-plan > "pr${pr}-plan.json"
  
  # Phase 3: Implementation (parallel workers)
  # Launch 4 workers per PR
  for worker_id in 1 2 3 4; do
    (
      ASSIGNMENT=$(jq -r ".assignments.worker_${worker_id}[]" "pr${pr}-plan.json")
      for thread_id in $ASSIGNMENT; do
        implement-fix --pr "$pr" --thread "$thread_id"
      done
    ) &
  done
  wait  # Wait for all workers on this PR
  
  # Phase 4: Resolution (coordinator)
  jq -r '.threads[].id' "pr${pr}-threads.json" | while read tid; do
    gh pr-review resolve --pr "$pr" --thread-id "$tid"
  done
  
  echo "✓ PR #$pr complete"
}

export -f process_pr_parallel

# Run PRs in parallel (max N concurrent)
printf '%s\n' "${PR_NUMBERS[@]}" | \
  xargs -P "$MAX_CONCURRENT" -I {} bash -c 'process_pr_parallel {}'

echo "All PRs processed!"
```

---

## Gating Patterns

### Pattern 1: Independent Verification (Recommended)

Each PR is verified and resolved independently - maximum speed, fault isolation.

```bash
for pr in "${PR_NUMBERS[@]}"; do
  (
    # Full workflow for this PR
    process_pr_parallel "$pr"
    
    # Verify THIS PR only
    if run_pr_tests "$pr"; then
      approve_pr "$pr"
    else
      echo "PR #$pr failed tests"
    fi
  ) &
done

wait
echo "All PRs processed independently"
```

**Benefits:**
- ✅ Fast: No cross-PR blocking
- ✅ Isolated: One PR failure doesn't block others
- ✅ Parallel approvals: Multiple PRs can merge simultaneously

**Use when:** PRs are completely independent (different features/files)

**Token cost:** N × 5,100 (each PR independent)  
**Time:** ~15 minutes (all PRs in parallel)

---

### Pattern 2: Batch Verification with Gating

Process all PRs, then verify integration - ensures all changes work together.

```bash
# Stage 1: Resolve all PRs in parallel
for pr in "${PR_NUMBERS[@]}"; do
  process_pr_parallel "$pr" &
done
wait

echo "=== GATE: All PRs resolved, starting verification ==="

# Stage 2: Integration testing (sequential or parallel)
failed_prs=()
for pr in "${PR_NUMBERS[@]}"; do
  if ! run_pr_tests "$pr"; then
    failed_prs+=("$pr")
  fi
done

# Stage 3: Approve only if ALL passed
if [ ${#failed_prs[@]} -eq 0 ]; then
  echo "All PRs passed - approving batch"
  for pr in "${PR_NUMBERS[@]}"; do
    approve_pr "$pr"
  done
else
  echo "Failed PRs: ${failed_prs[*]} - no approvals"
  exit 1
fi
```

**Benefits:**
- ✅ Safe: Ensure all changes work together
- ✅ Atomic: All-or-nothing batch approval
- ✅ Integration testing: Catch cross-PR conflicts

**Use when:** PRs touch related code, need integration verification

**Token cost:** N × 5,100  
**Time:** ~20 minutes (15 min resolution + 5 min integration tests)

---

### Pattern 3: Progressive Rollout

Process PRs in priority order with checkpoints - risk management.

```bash
# High priority first
process_pr_parallel 101 &
pid_101=$!

# Wait for high-priority to complete
wait $pid_101
if run_pr_tests 101; then
  approve_pr 101
  
  # Gate passed - start medium priority
  process_pr_parallel 102 &
  process_pr_parallel 103 &
  wait
  
  # Verify batch
  if run_pr_tests 102 && run_pr_tests 103; then
    approve_pr 102
    approve_pr 103
  fi
else
  echo "Critical PR 101 failed - stopping pipeline"
  exit 1
fi
```

**Benefits:**
- ✅ Risk management: Critical PRs first
- ✅ Early feedback: Fail fast on important changes
- ✅ Resource optimization: Don't waste effort if foundation broken

**Use when:** PRs have dependencies or priority order

**Token cost:** N × 5,100  
**Time:** ~25 minutes (sequential gates add overhead)

---

## Failure Handling Strategies

### Strategy 1: Continue-on-Error

Best for independent PRs - maximize throughput.

```bash
successful_prs=()
failed_prs=()

for pr in "${PR_NUMBERS[@]}"; do
  if process_pr_parallel "$pr"; then
    successful_prs+=("$pr")
  else
    failed_prs+=("$pr")
  fi &
done

wait

echo "Successful: ${successful_prs[*]}"
echo "Failed: ${failed_prs[*]}"
```

**Use when:** PRs are independent, want to resolve as many as possible

---

### Strategy 2: Fail-Fast

Best for related PRs - stop on first failure.

```bash
set -e  # Exit on any failure

for pr in "${PR_NUMBERS[@]}"; do
  process_pr_parallel "$pr" &
  pids+=($!)
done

# If any fails, all abort
for pid in "${pids[@]}"; do
  wait "$pid" || exit 1
done
```

**Use when:** PRs are dependent, no point continuing if one fails

---

### Strategy 3: Retry Failed PRs

Best for transient failures - automatic recovery.

```bash
failed_prs=()

# First attempt
for pr in "${PR_NUMBERS[@]}"; do
  process_pr_parallel "$pr" || failed_prs+=("$pr") &
done
wait

# Retry failures (up to 2 more attempts)
for attempt in 2 3; do
  if [ ${#failed_prs[@]} -eq 0 ]; then
    break
  fi
  
  echo "Retry attempt $attempt for: ${failed_prs[*]}"
  retry_prs=("${failed_prs[@]}")
  failed_prs=()
  
  for pr in "${retry_prs[@]}"; do
    process_pr_parallel "$pr" || failed_prs+=("$pr") &
  done
  wait
done

if [ ${#failed_prs[@]} -gt 0 ]; then
  echo "Permanently failed: ${failed_prs[*]}"
  exit 1
fi
```

**Use when:** Network/API issues common, want automatic recovery

---

## Resource Management

### Limit Total Concurrent Agents

Respect platform/infrastructure limits.

```bash
# Example: Platform limits to 10 concurrent LLM agents
# Each PR uses 5 agents (1 coordinator + 4 workers)
# Therefore: max 2 PRs at a time

MAX_CONCURRENT_PRS=2  # 2 PRs × 5 agents = 10 total

printf '%s\n' "${PR_NUMBERS[@]}" | \
  xargs -P "$MAX_CONCURRENT_PRS" -I {} bash -c 'process_pr_parallel {}'
```

**Formula:** `MAX_CONCURRENT_PRS = PLATFORM_AGENT_LIMIT / AGENTS_PER_PR`

---

### Dynamic Scheduling by PR Size

Optimize resource utilization - small PRs first.

```bash
# Process small PRs first (finish fast, free up resources)
# Then tackle large PRs

small_prs=(101 103)  # 1-5 comments each
large_prs=(102)      # 20+ comments

# Small PRs in parallel (low resource usage)
for pr in "${small_prs[@]}"; do
  process_pr_parallel "$pr" &
done
wait

# Large PR alone (uses all available agents)
process_pr_parallel "${large_prs[0]}"
```

**Benefits:**
- Quick wins: Small PRs done fast
- Better throughput: Keep resources busy
- User experience: Show progress early

---

## Monitoring Multiple PRs

### Terminal 1: Overall Progress

```bash
watch -n 5 'echo "=== PR Status ==="; \
  for pr in 101 102 103; do \
    REMAINING=$(gh pr-review unresolved --pr $pr --json | jq ".threads | length"); \
    echo "PR #$pr: $REMAINING unresolved"; \
  done'
```

### Terminal 2: Resource Usage

```bash
watch -n 5 'echo "Active agents:"; \
  ps aux | grep -E "coordinator|worker" | wc -l'
```

### Terminal 3: Logs

```bash
# Tail logs for all PRs
tail -f pr{101,102,103}.log
```

### Python Monitoring Script

```python
#!/usr/bin/env python3
import subprocess
import json
import time

def monitor_prs(pr_numbers):
    """Monitor progress of multiple PRs."""
    while True:
        print("\n=== PR Status ===")
        all_done = True
        
        for pr in pr_numbers:
            result = subprocess.run(
                ["gh", "pr-review", "unresolved", "--pr", str(pr), "--json"],
                capture_output=True, text=True
            )
            data = json.loads(result.stdout)
            remaining = len(data.get("threads", []))
            
            status = "✓ Done" if remaining == 0 else f"{remaining} remaining"
            print(f"PR #{pr}: {status}")
            
            if remaining > 0:
                all_done = False
        
        if all_done:
            print("\n✓ All PRs complete!")
            break
        
        time.sleep(5)

if __name__ == "__main__":
    monitor_prs([101, 102, 103])
```

---

## Performance Analysis

### Example: 3 PRs, Each with 20 Comments

**Sequential (no parallelization):**
- 60 comments × 3 min = 180 minutes (~3 hours)
- Tokens: 7,000 × 3 = 21,000

**Multi-PR only (parallel PRs, sequential within each):**
- 20 comments × 3 min = 60 minutes (3 PRs in parallel)
- Tokens: 7,000 × 3 = 21,000

**Multi-PR + Parallel Workflow (optimal):**
- 5 comments × 3 min = 15 minutes (3 PRs parallel, 4 workers each)
- Tokens: 5,100 × 3 = 15,300
- **Result: 12x faster, 27% fewer tokens**

### Scaling Analysis

| PRs | Comments Each | Sequential | Multi-PR + Parallel | Speedup |
|-----|---------------|------------|---------------------|---------|
| 1   | 20            | 60 min     | 15 min              | 4x      |
| 3   | 20            | 180 min    | 15 min              | 12x     |
| 5   | 20            | 300 min    | 15 min              | 20x     |
| 10  | 20            | 600 min    | 30 min (2 batches)  | 20x     |

**Key insight:** Speedup scales with number of PRs (parallel) AND comments per PR (parallel workers).

---

## Decision Matrix

| Scenario | Pattern | Gating | Tokens | Time | Best For |
|----------|---------|--------|--------|------|----------|
| 3 independent PRs, 20 comments each | Multi-PR + Parallel | Independent | 15,300 | 15 min | Maximum speed |
| 3 related PRs, need integration test | Multi-PR + Parallel | Batch verification | 15,300 | 20 min | Safety |
| 1 critical + 2 low-priority | Progressive rollout | Sequential gates | 15,300 | 25 min | Risk management |
| 5 small PRs (3-5 comments) | Multi-PR only | Independent | 35,000 | 10 min | Simple PRs |

---

## Common Patterns by Use Case

### Daily PR Cleanup (10-20 PRs)

```bash
# Fetch all open PRs
PRS=$(gh pr list --json number -q '.[].number')

# Process all in parallel (adjust MAX_CONCURRENT for your infrastructure)
echo "$PRS" | xargs -P 5 -I {} bash -c 'process_pr_parallel {}'
```

### Release Branch Preparation

```bash
# All PRs must pass together for release
# Use batch verification pattern
process_all_prs_batch_gated "${RELEASE_PRS[@]}"
```

### Hot-Fix PRs (Priority)

```bash
# Critical fixes first, then others
# Use progressive rollout pattern
process_critical_first "${CRITICAL_PRS[@]}" "${NORMAL_PRS[@]}"
```

---

## Key Decisions

When orchestrating multiple PRs, decide:

1. **Gating strategy:**
   - Independent verification? (fastest, most isolated)
   - Batch verification? (safest, ensures integration)
   - Progressive rollout? (risk-managed, priority-based)

2. **Failure handling:**
   - Continue-on-error? (maximize throughput)
   - Fail-fast? (stop on first problem)
   - Retry logic? (handle transient failures)

3. **Resource limits:**
   - How many concurrent PRs? (infrastructure capacity)
   - How many agents per PR? (5 = 1 coordinator + 4 workers typical)
   - Dynamic scheduling? (small PRs first)

4. **Priority ordering:**
   - Process all equally? (independent verification)
   - Critical first? (progressive rollout)
   - By size? (small first for quick wins)

---

## Default Recommendations

**For most teams:**
- ✅ Pattern: Independent verification
- ✅ Failure handling: Continue-on-error with logging
- ✅ Resource limits: MAX_CONCURRENT = PLATFORM_LIMIT / 5
- ✅ Priority: Process all PRs equally

**This maximizes:**
- Speed (no gating delays)
- Fault tolerance (isolated failures)
- Simplicity (no complex orchestration)

**Adjust if:**
- PRs are related → Use batch verification
- Infrastructure limited → Reduce MAX_CONCURRENT
- Critical fixes exist → Use progressive rollout

---

## Related

- [[parallel-workflow]] - Single PR parallelization
- [[parallel-execution-techniques]] - Bash/Python implementation patterns
- [[gh-pr-review-guide]] - Tool for deterministic PR operations

---

[parallel-workflow]: ../../_shared/patterns/parallel-workflow.md "Intra-PR Parallel Workflow"
[parallel-execution-techniques]: ../../_shared/tools/parallel-execution-techniques.md "Parallel Execution Techniques"
[gh-pr-review-guide]: gh-pr-review-guide.md "gh-pr-review Tool Guide"