# Technical Reference

Consolidated reference guide for tools and techniques used across workflows.

## GitHub APIs

For detailed reference, see `github-apis.md`.

**Quick Summary:**
- GraphQL for complex queries (PR data, comments, reviews)
- REST for simple operations (create issues, update PRs)
- `gh` CLI for reproducible, deterministic operations
- Personal access token or device flow for authentication

## Parallel Execution Techniques

For detailed code examples, see [[parallel-execution-techniques]].

**Quick Summary:**

### Bash

**xargs** (simple parallelization):
```bash
cat pr_ids.txt | xargs -P 4 -I {} sh -c 'gh pr view {} --json comments'
```

**GNU Parallel** (advanced):
```bash
cat pr_ids.txt | parallel -j 4 'gh pr view {} --json comments > {}.json'
```

**Background jobs**:
```bash
for id in $(cat pr_ids.txt); do
  (gh pr view "$id" --json comments > "$id.json") &
done
wait
```

### Python

**asyncio** (concurrent execution):
```python
import asyncio
import subprocess

async def fetch_pr(pr_id):
    proc = await asyncio.create_subprocess_exec(
        'gh', 'pr', 'view', pr_id, '--json', 'comments'
    )
    return await proc.communicate()

async def main():
    tasks = [fetch_pr(pr_id) for pr_id in pr_ids]
    results = await asyncio.gather(*tasks)
```

**concurrent.futures** (thread/process pools):
```python
from concurrent.futures import ThreadPoolExecutor, as_completed

with ThreadPoolExecutor(max_workers=4) as executor:
    futures = {executor.submit(fetch_pr, pr_id): pr_id for pr_id in pr_ids}
    for future in as_completed(futures):
        result = future.result()
```

## Shared Patterns

See [[patterns/]] for full documentation:

- **parallel-workflow.md** - Coordinator + worker pattern
- **interactive-workflow.md** - Human-in-the-loop decisions

## Common Tasks

### Fetching PR Data

```bash
gh pr view <PR> --json title,body,comments,reviews,commits
```

### Creating Batch Operations

```bash
# Parallel: Resolve 10 PRs concurrently
cat pr_list.txt | xargs -P 4 -I {} sh -c './resolve-pr.sh {}'

# Sequential: With monitoring
for pr in $(cat pr_list.txt); do
  echo "Processing PR $pr..."
  ./resolve-pr.sh "$pr" || echo "FAILED: $pr"
done
```

### Error Handling

**Strategy 1: Continue on error**
```bash
set +e  # don't exit on error
for item in $(cat list.txt); do
  process "$item" || echo "FAILED: $item" >> failures.txt
done
```

**Strategy 2: Fail fast**
```bash
set -e  # exit on error
for item in $(cat list.txt); do
  process "$item"
done
```

**Strategy 3: Retry with backoff**
```bash
retry_with_backoff() {
  local max_attempts=3
  local attempt=1
  while [ $attempt -le $max_attempts ]; do
    "$@" && return 0
    sleep $((2 ** attempt))
    attempt=$((attempt + 1))
  done
  return 1
}
```

## For More Information

- **API Details:** See [[github-apis]]
- **Code Examples:** See [[parallel-execution-techniques]]
- **Workflow Patterns:** See [[patterns/]]
- **Workflow Example:** See [[pr-comment-resolution/]]


[parallel-execution-techniques]: parallel-execution-techniques.md "Parallel Execution Techniques"
[patterns/]: ../patterns/


[github-apis]: github-apis.md "GitHub APIs Reference"
[pr-comment-resolution/]: ../../../temple/workflows/pr-comment-resolution/