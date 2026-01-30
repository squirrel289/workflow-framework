# Parallel Execution Techniques

Technical reference for implementing parallel workflows using bash, Python, and shell tools.

**When to load this:** When actively implementing parallel execution logic. Not needed for planning or understanding the workflow pattern.

## Table of Contents

- [Bash Parallel Execution](#bash-parallel-execution)
- [Python Asyncio Patterns](#python-asyncio-patterns)
- [Dependency Management](#dependency-management)
- [Error Handling](#error-handling)
- [Monitoring & Debugging](#monitoring--debugging)

---

## Bash Parallel Execution

### Using GNU Parallel

**Installation:**
```bash
# macOS
brew install parallel

# Ubuntu/Debian
apt-get install parallel
```

**Basic parallel execution:**
```bash
# Process list of items in parallel with 4 workers
cat items.txt | parallel --jobs 4 process_item {}

# Export function for parallel to use
process_item() {
  echo "Processing $1..."
  # Your logic here
}
export -f process_item

# Run with exported function
seq 1 10 | parallel process_item {}
```

**Parallel with context:**
```bash
# Pass multiple arguments
parallel --jobs 4 --colsep ',' process_thread {1} {2} {3} :::: threads.csv

# Example threads.csv:
# thread_id,file_path,line_number
# PRRT_1,src/auth.py,42
# PRRT_2,src/utils.py,15
```

**Progress monitoring:**
```bash
# Show progress bar
parallel --jobs 4 --bar process_item :::: items.txt

# Show job log
parallel --jobs 4 --joblog parallel.log process_item :::: items.txt
cat parallel.log  # See timing, exit codes
```

### Using xargs

**Basic parallel execution:**
```bash
# Run 4 jobs in parallel
cat items.txt | xargs -P 4 -I {} process_item.sh {}

# Process files
find . -name "*.py" | xargs -P 4 -I {} python -m pylint {}
```

**With error handling:**
```bash
# Stop all on first error
cat items.txt | xargs -P 4 -I {} bash -c 'process_item.sh {} || exit 255'

# Continue on errors, collect exit codes
cat items.txt | xargs -P 4 -I {} bash -c 'process_item.sh {} || echo "FAILED: {}"'
```

### Background Jobs (Pure Bash)

**Basic pattern:**
```bash
#!/bin/bash

# Launch background jobs
for item in item1 item2 item3; do
  (
    echo "Processing $item..."
    process_item "$item"
  ) &
done

# Wait for all to complete
wait
echo "All jobs complete"
```

**With PID tracking:**
```bash
#!/bin/bash

pids=()

# Launch and track PIDs
for item in item1 item2 item3; do
  process_item "$item" &
  pids+=($!)
done

# Wait and check exit codes
for pid in "${pids[@]}"; do
  if wait "$pid"; then
    echo "PID $pid succeeded"
  else
    echo "PID $pid failed"
  fi
done
```

**Semaphore (limit concurrency):**
```bash
#!/bin/bash

max_jobs=4
job_count=0

for item in "${items[@]}"; do
  # Wait if at max jobs
  while [ "$job_count" -ge "$max_jobs" ]; do
    wait -n  # Wait for any job to finish
    job_count=$((job_count - 1))
  done
  
  # Launch new job
  process_item "$item" &
  job_count=$((job_count + 1))
done

wait  # Wait for remaining jobs
```

---

## Python Asyncio Patterns

### Basic Concurrent Execution

```python
import asyncio
from typing import List

async def process_thread(thread_id: str) -> bool:
    """Process a single thread asynchronously."""
    print(f"Processing {thread_id}...")
    # Simulate async work
    await asyncio.sleep(2)
    return True

async def process_all_threads(thread_ids: List[str]):
    """Process all threads concurrently."""
    tasks = [process_thread(tid) for tid in thread_ids]
    results = await asyncio.gather(*tasks)
    return results

# Run
thread_ids = ["PRRT_1", "PRRT_2", "PRRT_3"]
results = asyncio.run(process_all_threads(thread_ids))
```

### With Error Handling

```python
async def process_all_threads(thread_ids: List[str]):
    """Process threads with individual error handling."""
    tasks = [process_thread(tid) for tid in thread_ids]
    
    # return_exceptions=True prevents one failure from canceling others
    results = await asyncio.gather(*tasks, return_exceptions=True)
    
    # Check results
    for tid, result in zip(thread_ids, results):
        if isinstance(result, Exception):
            print(f"❌ {tid} failed: {result}")
        else:
            print(f"✓ {tid} succeeded")
    
    return results
```

### Semaphore (Limit Concurrency)

```python
import asyncio

async def process_thread_with_limit(
    thread_id: str, 
    semaphore: asyncio.Semaphore
) -> bool:
    """Process thread with concurrency limit."""
    async with semaphore:
        # Only N threads will run concurrently
        print(f"Processing {thread_id}...")
        await asyncio.sleep(2)
        return True

async def process_all_with_limit(thread_ids: List[str], max_concurrent: int = 4):
    """Process threads with concurrency limit."""
    semaphore = asyncio.Semaphore(max_concurrent)
    tasks = [
        process_thread_with_limit(tid, semaphore) 
        for tid in thread_ids
    ]
    return await asyncio.gather(*tasks)

# Run with max 4 concurrent
results = asyncio.run(process_all_with_limit(thread_ids, max_concurrent=4))
```

### Progress Monitoring

```python
import asyncio
from tqdm.asyncio import tqdm

async def process_with_progress(thread_ids: List[str]):
    """Process threads with progress bar."""
    tasks = [process_thread(tid) for tid in thread_ids]
    
    # Progress bar wrapper
    results = []
    for coro in tqdm.as_completed(tasks, total=len(tasks)):
        result = await coro
        results.append(result)
    
    return results
```

### Subprocess Integration

```python
import asyncio

async def run_subprocess(cmd: List[str]) -> tuple[int, str, str]:
    """Run subprocess asynchronously."""
    proc = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )
    stdout, stderr = await proc.communicate()
    return proc.returncode, stdout.decode(), stderr.decode()

async def parallel_subprocess_execution(commands: List[List[str]]):
    """Run multiple commands in parallel."""
    tasks = [run_subprocess(cmd) for cmd in commands]
    results = await asyncio.gather(*tasks)
    return results

# Example
commands = [
    ["gh", "pr-review", "resolve", "--thread-id", "PRRT_1"],
    ["gh", "pr-review", "resolve", "--thread-id", "PRRT_2"],
    ["gh", "pr-review", "resolve", "--thread-id", "PRRT_3"],
]
results = asyncio.run(parallel_subprocess_execution(commands))
```

---

## Dependency Management

### DAG (Directed Acyclic Graph) Execution

```python
from typing import Dict, List, Set
import asyncio

class DependencyGraph:
    def __init__(self):
        self.nodes: Dict[str, asyncio.Task] = {}
        self.dependencies: Dict[str, Set[str]] = {}
    
    def add_task(self, task_id: str, depends_on: List[str] = None):
        """Add task with dependencies."""
        self.dependencies[task_id] = set(depends_on or [])
    
    async def execute_task(self, task_id: str, task_func):
        """Execute task after dependencies complete."""
        # Wait for dependencies
        deps = self.dependencies.get(task_id, set())
        if deps:
            await asyncio.gather(*[self.nodes[dep] for dep in deps])
        
        # Execute this task
        print(f"Executing {task_id}...")
        result = await task_func(task_id)
        return result
    
    async def execute_all(self, tasks: Dict[str, callable]):
        """Execute all tasks respecting dependencies."""
        # Create tasks for all nodes
        for task_id, task_func in tasks.items():
            self.nodes[task_id] = asyncio.create_task(
                self.execute_task(task_id, task_func)
            )
        
        # Wait for all to complete
        results = await asyncio.gather(*self.nodes.values())
        return results

# Usage
graph = DependencyGraph()
graph.add_task("task_a", depends_on=[])
graph.add_task("task_b", depends_on=["task_a"])
graph.add_task("task_c", depends_on=["task_a"])
graph.add_task("task_d", depends_on=["task_b", "task_c"])

async def example_task(task_id: str):
    await asyncio.sleep(1)
    return f"{task_id} complete"

tasks = {
    "task_a": example_task,
    "task_b": example_task,
    "task_c": example_task,
    "task_d": example_task,
}

results = asyncio.run(graph.execute_all(tasks))
```

### Batch Processing with Dependencies

```bash
#!/bin/bash
# Process in batches with dependencies

# Batch 1 (parallel within batch)
echo "=== Batch 1 ==="
parallel --jobs 4 process_item ::: item_a item_b item_c item_d
batch1_exit=$?

# Only proceed if Batch 1 succeeded
if [ $batch1_exit -eq 0 ]; then
  echo "=== Batch 2 ==="
  parallel --jobs 4 process_item ::: item_e item_f
else
  echo "Batch 1 failed, skipping Batch 2"
  exit 1
fi
```

---

## Error Handling

### Retry Logic (Python)

```python
import asyncio
from typing import TypeVar, Callable

T = TypeVar('T')

async def retry_async(
    func: Callable[..., T],
    max_retries: int = 3,
    delay: float = 1.0,
    *args,
    **kwargs
) -> T:
    """Retry async function with exponential backoff."""
    for attempt in range(max_retries):
        try:
            return await func(*args, **kwargs)
        except Exception as e:
            if attempt == max_retries - 1:
                raise
            wait_time = delay * (2 ** attempt)
            print(f"Attempt {attempt + 1} failed: {e}. Retrying in {wait_time}s...")
            await asyncio.sleep(wait_time)

# Usage
async def flaky_operation(thread_id: str):
    # Might fail
    result = await process_thread(thread_id)
    return result

result = await retry_async(flaky_operation, max_retries=3, delay=1.0, thread_id="PRRT_1")
```

### Fail-Fast vs Continue-On-Error (Bash)

```bash
# Fail-fast: Stop all on first error
set -e
for item in "${items[@]}"; do
  process_item "$item" || exit 1
done

# Continue on error: Collect failures
failed_items=()
for item in "${items[@]}"; do
  if ! process_item "$item"; then
    failed_items+=("$item")
  fi
done

if [ ${#failed_items[@]} -gt 0 ]; then
  echo "Failed items: ${failed_items[*]}"
  exit 1
fi
```

---

## Monitoring & Debugging

### Progress Tracking (Bash)

```bash
#!/bin/bash
total=${#items[@]}
completed=0

for item in "${items[@]}"; do
  process_item "$item" &
  pids+=($!)
done

# Monitor progress
for pid in "${pids[@]}"; do
  wait "$pid"
  completed=$((completed + 1))
  echo "Progress: $completed/$total"
done
```

### Logging (Python)

```python
import asyncio
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)

async def process_thread_logged(thread_id: str):
    """Process thread with detailed logging."""
    logger = logging.getLogger(thread_id)
    
    logger.info(f"Starting {thread_id}")
    try:
        result = await process_thread(thread_id)
        logger.info(f"Completed {thread_id}")
        return result
    except Exception as e:
        logger.error(f"Failed {thread_id}: {e}")
        raise
```

### Performance Profiling

```bash
# Time each parallel task
parallel --jobs 4 --joblog timing.log process_item :::: items.txt

# Analyze timing
column -t timing.log | sort -k4 -n  # Sort by runtime
```

```python
import time
import asyncio

async def profile_execution(thread_ids: List[str]):
    """Profile parallel execution."""
    start = time.time()
    
    tasks = []
    for tid in thread_ids:
        task_start = time.time()
        tasks.append(process_thread(tid))
    
    results = await asyncio.gather(*tasks)
    
    end = time.time()
    print(f"Total time: {end - start:.2f}s")
    print(f"Average per thread: {(end - start) / len(thread_ids):.2f}s")
    
    return results
```

---

## Real-World Examples

### Parallel PR Resolution Implementation

```python
#!/usr/bin/env python3
"""
Complete parallel PR resolution implementation.
"""
import asyncio
import json
import subprocess
from typing import List, Dict

async def fetch_threads(pr: int) -> List[Dict]:
    """Phase 1: Research - Fetch unresolved threads."""
    proc = await asyncio.create_subprocess_exec(
        "gh", "pr-review", "unresolved", "--pr", str(pr), "--json",
        stdout=asyncio.subprocess.PIPE
    )
    stdout, _ = await proc.communicate()
    data = json.loads(stdout)
    return data.get("threads", [])

def categorize_threads(threads: List[Dict]) -> Dict[str, List[str]]:
    """Phase 2: Planning - Categorize by complexity."""
    # Simple categorization by file count
    simple = [t["id"] for t in threads if len(t.get("files", [])) == 1]
    complex = [t["id"] for t in threads if len(t.get("files", [])) > 1]
    
    # Assign to workers (3 workers in this example)
    assignments = {
        "worker_1": simple[:5],
        "worker_2": simple[5:10],
        "worker_3": complex,
    }
    return assignments

async def implement_thread(thread_id: str, thread_data: Dict) -> bool:
    """Phase 3: Implementation - Process single thread."""
    print(f"Worker processing {thread_id}...")
    # Your implementation logic here
    await asyncio.sleep(2)  # Simulate work
    return True

async def resolve_thread(thread_id: str, pr: int):
    """Resolve a single thread via gh-pr-review."""
    await asyncio.create_subprocess_exec(
        "gh", "pr-review", "resolve",
        "--pr", str(pr),
        "--thread-id", thread_id,
        "--comment", "Fixed ✓"
    )

async def main(pr: int):
    """Complete parallel PR workflow."""
    # Phase 1: Research (coordinator)
    print("=== Phase 1: Research ===")
    threads = await fetch_threads(pr)
    print(f"Found {len(threads)} threads")
    
    # Phase 2: Planning (coordinator)
    print("=== Phase 2: Planning ===")
    assignments = categorize_threads(threads)
    print(f"Assignments: {assignments}")
    
    # Phase 3: Implementation (parallel workers)
    print("=== Phase 3: Implementation (Parallel) ===")
    tasks = []
    thread_lookup = {t["id"]: t for t in threads}
    
    for worker, thread_ids in assignments.items():
        for tid in thread_ids:
            tasks.append(implement_thread(tid, thread_lookup[tid]))
    
    results = await asyncio.gather(*tasks, return_exceptions=True)
    print(f"Implementation complete: {sum(1 for r in results if r is True)}/{len(results)} succeeded")
    
    # Phase 4: Resolution (coordinator)
    print("=== Phase 4: Resolution ===")
    resolution_tasks = [resolve_thread(t["id"], pr) for t in threads]
    await asyncio.gather(*resolution_tasks)
    print(f"✓ PR #{pr} fully resolved")

if __name__ == "__main__":
    asyncio.run(main(pr=123))
```

---

## When to Use Each Tool

| Tool | Best For | Pros | Cons |
|------|----------|------|------|
| GNU `parallel` | Shell scripts, file processing | Feature-rich, easy | External dependency |
| `xargs -P` | Simple parallel execution | Built-in, fast | Limited features |
| Bash background jobs | Pure bash, no dependencies | Native, portable | Manual management |
| Python `asyncio` | Complex logic, API calls | Full control, error handling | More code |
| Subprocess pools | Mixed shell/Python | Flexibility | Complexity |

---

**Next Steps:**
- For workflow patterns, see: [[parallel-workflow]]
- For ready-to-use scripts, see: [[shell-scripts/]]
- For tool guides, see: [[gh-pr-review-guide]]


[parallel-workflow]: ../patterns/parallel-workflow.md "Intra-PR Parallel Workflow"
[gh-pr-review-guide]: ../../pr-comment-resolution/tools/gh-pr-review-guide.md "gh-pr-review Tool Guide"
[shell-scripts/]: ../../pr-comment-resolution/templates/shell-scripts/