# Full Automation Guide

Complete end-to-end automation for PR comment resolution.

## Overview

This guide shows how to fully automate PR resolution using LLM agents or scripts, executing all 4 phases sequentially with minimal human intervention.

## Prerequisites

- `gh` CLI installed and authenticated
- `gh-pr-review` extension installed
- LLM agent with file editing capabilities
- Git repository access

## Complete Workflow

### Phase 1: Context Gathering (Automated)

```bash
#!/bin/bash
# Gather all necessary context for the agent

PR_NUMBER="${1:-}"
OWNER="owner"
REPO="repo"

# Fetch unresolved threads
gh pr-review review view -R "$OWNER/$REPO" --pr "$PR_NUMBER" \
  --unresolved --not_outdated > context/unresolved.json

# Get PR metadata
gh pr view "$PR_NUMBER" --json title,body,files > context/pr_meta.json

# Get file contents for changed files
jq -r '.files[].filename' context/pr_meta.json | while read -r file; do
  mkdir -p "context/files/$(dirname "$file")"
  cp "$file" "context/files/$file"
done

# Get test file locations
find tests/ -name "test_*.py" > context/test_files.txt

echo "Context gathered in context/ directory"
```

**Prompt for LLM:**
```
I need you to resolve all unresolved PR comments. Here's the context:

1. Unresolved threads (JSON): [attach context/unresolved.json]
2. PR metadata: [attach context/pr_meta.json]
3. Affected files: [attach context/files/*]
4. Test locations: [attach context/test_files.txt]

Please:
1. Analyze each unresolved thread
2. Implement the requested changes
3. Add or update tests
4. Verify all tests pass
5. Commit each change with clear messages
6. Report back with thread IDs for resolution
```

### Phase 2: Planning (Automated)

```python
# plan_resolution.py
import json
from typing import List, Dict, Set

def analyze_dependencies(threads: List[Dict]) -> Dict[str, List[str]]:
    """
    Analyze thread dependencies based on affected files.
    Returns a dependency graph.
    """
    file_threads = {}
    for thread in threads:
        file_path = thread["path"]
        if file_path not in file_threads:
            file_threads[file_path] = []
        file_threads[file_path].append(thread["thread_id"])
    
    return file_threads

def create_execution_plan(threads: List[Dict]) -> Dict[str, List[Dict]]:
    """
    Create batches of threads that can be executed in parallel.
    """
    dependencies = analyze_dependencies(threads)
    
    # Group independent files into batches
    batches = {"batch_1": []}
    for file_path, thread_ids in dependencies.items():
        file_threads = [t for t in threads if t["path"] == file_path]
        batches["batch_1"].extend(file_threads)
    
    return batches

def main():
    with open("context/unresolved.json") as f:
        data = json.load(f)
    
    threads = []
    for review in data["reviews"]:
        for comment in review.get("comments", []):
            threads.append({
                "thread_id": comment["thread_id"],
                "path": comment["path"],
                "line": comment.get("line"),
                "request": comment["body"],
                "author": comment["author_login"]
            })
    
    plan = create_execution_plan(threads)
    
    with open("context/execution_plan.json", "w") as f:
        json.dump(plan, f, indent=2)
    
    print(f"Execution plan created: {len(plan)} batches")
    for batch_name, batch_threads in plan.items():
        print(f"  {batch_name}: {len(batch_threads)} threads")

if __name__ == "__main__":
    main()
```

### Phase 3: Implementation (Automated)

```bash
#!/bin/bash
# implement_changes.sh
# Execute the plan created in Phase 2

OWNER="owner"
REPO="repo"
PR_NUMBER="$1"

# Load execution plan
PLAN_FILE="context/execution_plan.json"

# Process each batch
jq -c '.[]' "$PLAN_FILE" | while read -r batch; do
  echo "Processing batch..."
  
  echo "$batch" | jq -c '.[]' | while read -r thread; do
    thread_id=$(echo "$thread" | jq -r '.thread_id')
    file_path=$(echo "$thread" | jq -r '.path')
    request=$(echo "$thread" | jq -r '.request')
    
    echo "Processing $thread_id: $file_path"
    
    # Call LLM agent to implement change
    llm_agent implement-change \
      --file "$file_path" \
      --request "$request" \
      --thread-id "$thread_id"
    
    # Run tests
    pytest "tests/test_$(basename "$file_path" .py).py"
    
    if [ $? -eq 0 ]; then
      # Tests passed, commit
      git add "$file_path" "tests/test_$(basename "$file_path" .py).py"
      git commit -m "fix: $request (thread $thread_id)"
      
      # Reply to thread
      gh pr-review comments reply "$PR_NUMBER" -R "$OWNER/$REPO" \
        --thread-id "$thread_id" \
        --body "Implemented in commit $(git rev-parse --short HEAD)"
      
      echo "✓ Completed $thread_id"
    else
      echo "❌ Tests failed for $thread_id"
      git reset --hard
    fi
  done
done
```

### Phase 4: Resolution (Automated)

```bash
#!/bin/bash
# resolve_threads.sh
# Resolve all successfully implemented threads

OWNER="owner"
REPO="repo"
PR_NUMBER="$1"

# Get list of implemented threads from commits
git log --grep="thread " --format="%s" | \
  grep -oP 'thread \K[A-Z0-9_]+' | \
  sort -u > implemented_threads.txt

# Resolve each thread
while read -r thread_id; do
  gh pr-review threads resolve "$PR_NUMBER" -R "$OWNER/$REPO" \
    --thread-id "$thread_id"
  echo "✓ Resolved $thread_id"
done < implemented_threads.txt

# Verify no unresolved threads remain
UNRESOLVED=$(gh pr-review review view -R "$OWNER/$REPO" --pr "$PR_NUMBER" --unresolved)
if [ "$(echo "$UNRESOLVED" | jq '.reviews | length')" -eq 0 ]; then
  echo "✅ All threads resolved!"
else
  echo "⚠️ Some threads remain unresolved"
  echo "$UNRESOLVED" | jq '.reviews[].comments[].thread_id'
fi
```

## Complete Automation Script

```bash
#!/bin/bash
# auto_resolve_pr.sh
# Complete end-to-end PR comment resolution

set -euo pipefail

PR_NUMBER="${1:-}"
OWNER="${2:-owner}"
REPO="${3:-repo}"

if [ -z "$PR_NUMBER" ]; then
  echo "Usage: $0 <PR_NUMBER> [OWNER] [REPO]"
  exit 1
fi

echo "🚀 Starting automated PR resolution for #$PR_NUMBER"

# Phase 1: Gather context
echo "📊 Phase 1: Gathering context..."
mkdir -p context
gh pr-review review view -R "$OWNER/$REPO" --pr "$PR_NUMBER" \
  --unresolved --not_outdated > context/unresolved.json

THREAD_COUNT=$(jq '.reviews[].comments | length' context/unresolved.json | awk '{s+=$1} END {print s}')
echo "Found $THREAD_COUNT unresolved threads"

if [ "$THREAD_COUNT" -eq 0 ]; then
  echo "✅ No unresolved threads, nothing to do"
  exit 0
fi

# Phase 2: Create execution plan
echo "📋 Phase 2: Creating execution plan..."
python3 plan_resolution.py

# Phase 3: Implement changes
echo "🔨 Phase 3: Implementing changes..."
./implement_changes.sh "$PR_NUMBER"

# Run full test suite
echo "🧪 Running full test suite..."
pytest

if [ $? -ne 0 ]; then
  echo "❌ Test suite failed, rolling back..."
  git reset --hard HEAD~$THREAD_COUNT
  exit 1
fi

# Phase 4: Resolve threads
echo "✅ Phase 4: Resolving threads..."
./resolve_threads.sh "$PR_NUMBER"

# Post summary comment
echo "📝 Posting resolution summary..."
SUMMARY=$(cat <<EOF
## Automated Resolution Summary

All review comments have been addressed:

### Resolved Threads: $THREAD_COUNT
$(jq -r '.reviews[].comments[] | "- [\(.thread_id)] \(.path):\(.line) - \(.body)"' context/unresolved.json)

### Test Results
$(pytest --tb=line 2>&1 | grep -E "passed|failed")

### Commits
$(git log --oneline -$THREAD_COUNT)

All threads resolved automatically ✅
EOF
)

gh pr comment "$PR_NUMBER" -R "$OWNER/$REPO" --body "$SUMMARY"

echo "🎉 PR resolution complete!"
```

## LLM-Specific Patterns

### Minimal Context Windows

For token efficiency, provide only essential data:

```bash
# Fetch only thread IDs and descriptions
gh pr-review review view -R owner/repo --pr 42 --unresolved | \
  jq -r '.reviews[].comments[] | "\(.thread_id)|\(.path)|\(.body)"' | \
  head -5  # Process in batches of 5

# Pass to LLM
cat <<EOF | llm-agent
Resolve these 5 threads:
$(gh pr-review review view -R owner/repo --pr 42 --unresolved | \
  jq -r '.reviews[].comments[] | "\(.thread_id): \(.path) - \(.body)"' | \
  head -5)

For each thread:
1. Read the file
2. Implement the requested change
3. Run tests
4. Commit with message referencing thread ID
EOF
```

### Iterative Resolution

```python
# resolve_iteratively.py
import json
import subprocess

BATCH_SIZE = 3  # Process 3 threads at a time

def get_unresolved_threads(owner, repo, pr):
    result = subprocess.run(
        ["gh", "pr-review", "review", "view", "-R", f"{owner}/{repo}",
         "--pr", str(pr), "--unresolved"],
        capture_output=True, text=True
    )
    data = json.loads(result.stdout)
    threads = []
    for review in data["reviews"]:
        for comment in review.get("comments", []):
            threads.append(comment)
    return threads

def process_batch(threads_batch):
    """Send batch to LLM for processing."""
    # Format threads for LLM
    context = "\n".join([
        f"Thread {t['thread_id']}: {t['path']}:{t.get('line', '?')} - {t['body']}"
        for t in threads_batch
    ])
    
    # Call LLM agent (pseudo-code)
    result = llm_agent.process(context)
    
    return result

def main():
    owner = "owner"
    repo = "repo"
    pr = 42
    
    while True:
        threads = get_unresolved_threads(owner, repo, pr)
        if not threads:
            print("✅ All threads resolved!")
            break
        
        print(f"📋 {len(threads)} threads remaining")
        
        # Process in batches
        batch = threads[:BATCH_SIZE]
        print(f"Processing batch of {len(batch)} threads...")
        
        process_batch(batch)
        
        # Verify progress
        remaining = get_unresolved_threads(owner, repo, pr)
        if len(remaining) >= len(threads):
            print("⚠️ No progress made, stopping")
            break

if __name__ == "__main__":
    main()
```

## Error Handling

### Test Failures

```bash
# If tests fail, rollback and report
if ! pytest; then
  echo "Tests failed, rolling back changes"
  git reset --hard HEAD~1
  
  # Comment on thread about failure
  gh pr-review comments reply "$PR_NUMBER" -R "$OWNER/$REPO" \
    --thread-id "$thread_id" \
    --body "❌ Attempted fix caused test failures. Needs manual review."
  
  exit 1
fi
```

### Merge Conflicts

```bash
# Before starting, ensure no conflicts
git fetch origin main
git merge origin/main

if [ $? -ne 0 ]; then
  echo "Merge conflicts detected, resolve manually first"
  exit 1
fi
```

### API Rate Limits

```python
import time
from functools import wraps

def rate_limit(max_calls=10, period=60):
    """Rate limit decorator for API calls."""
    calls = []
    
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            now = time.time()
            # Remove old calls
            calls[:] = [c for c in calls if c > now - period]
            
            if len(calls) >= max_calls:
                sleep_time = calls[0] + period - now
                print(f"Rate limit reached, sleeping {sleep_time:.1f}s")
                time.sleep(sleep_time)
            
            calls.append(now)
            return func(*args, **kwargs)
        return wrapper
    return decorator

@rate_limit(max_calls=5, period=60)
def resolve_thread(thread_id):
    subprocess.run(["gh", "pr-review", "threads", "resolve", "42", ...])
```

## Best Practices

1. **Start with small batches** - Process 3-5 threads at a time
2. **Verify after each batch** - Run tests, check for issues
3. **Commit atomically** - One commit per thread for traceability
4. **Use deterministic tools** - `gh-pr-review` over interactive tools
5. **Log everything** - Capture all output for debugging
6. **Have rollback plan** - Be ready to revert if things go wrong
7. **Monitor progress** - Track which threads are complete
8. **Handle errors gracefully** - Don't fail the entire run for one bad thread

## Monitoring & Observability

```bash
# Create a dashboard script
#!/bin/bash
# dashboard.sh

while true; do
  clear
  echo "=== PR Resolution Dashboard ==="
  echo ""
  echo "Unresolved threads:"
  gh pr-review threads list -R owner/repo 42 --unresolved | jq length
  echo ""
  echo "Recent commits:"
  git log --oneline -5
  echo ""
  echo "Test status:"
  pytest --collect-only 2>&1 | grep "test session starts"
  echo ""
  sleep 5
done
```

## Related

- [[parallel-workflow]] - For concurrent execution with multiple agents
- [[interactive-workflow]] - For human-in-the-loop automation
- [[gh-pr-review-guide]] - Tool reference
- [Automated script template](../templates/shell-scripts/automated-pr-resolution.sh)

---

[parallel-workflow]: ../../_shared/patterns/parallel-workflow.md "Intra-PR Parallel Workflow"
[interactive-workflow]: ../../_shared/patterns/interactive-workflow.md "Interactive Workflow Pattern"
[gh-pr-review-guide]: gh-pr-review-guide.md "gh-pr-review Tool Guide"