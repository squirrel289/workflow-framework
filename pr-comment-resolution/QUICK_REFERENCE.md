# PR Resolution Quick Reference

One-page cheat sheet for commands, scripts, and file references.

**→ Using LLM?** See [[START_HERE]] for loading strategies
**→ Framework?** See [[FRAMEWORK]]

## For LLMs: Minimal Context Loading

```bash
# Load only what you need for current phase
cat ../../_shared/phases/01-research-analysis.md tools/gh-pr-review-guide.md
# ~5KB per phase, load as you progress
```

## For Humans: Jump to What You Need

| Need | File | Size |
|------|------|------|
| Overview | [[workflow-framework/README]] | 3KB |
| Research | [[01-research-analysis]] | 4KB |
| Planning | [[02-planning]] | 5KB |
| Implementation | [[03-implementation]] | 7KB |
| Resolution | [[04-resolution-verification]] | 6KB |

## For Automation: Ready-to-Run Scripts

```bash
# Complete automation
./templates/shell-scripts/automated-pr-resolution.sh 42

# Just fetch threads
./templates/shell-scripts/fetch-unresolved.sh owner repo 42

# Just resolve threads
./templates/shell-scripts/resolve-threads.sh owner repo 42 threads.json
```

## Common Commands

### Research
```bash
gh pr-review review view -R owner/repo --pr 42 --unresolved --not_outdated
```

### Implement
```bash
# Make changes, then:
git add -A
git commit -m "fix: description (thread PRRT_...)"
pytest
```

### Resolve
```bash
gh pr-review threads resolve 42 -R owner/repo --thread-id PRRT_...
```

## Token Optimization

**For detailed loading strategies and token costs, see [[START_HERE]]

**Quick summary:**
- Single PR, simple: [[sequential-workflow]] (~2,000 tokens)
- Single PR, large (10+ comments): [[parallel-workflow]] (~3,700 tokens)
- Multiple PRs: Load phases individually per agent
- Stateful session: Load once, reuse context

## Quick Navigation

**Using LLM?** → [[START_HERE]] for complete loading guide

**Need specific phase?**
- Research: [[01-research-analysis]]
- Planning: [[02-planning]]
- Implementation: [[03-implementation]]
- Resolution: [[04-resolution-verification]]

**Need pattern?**
- Sequential workflow: [[sequential-workflow]]
- Parallel workflow: [[parallel-workflow]]
- Interactive: [[interactive-workflow]]

## Directory Structure

```
resolve-pr-comments/
├── README.md                          # Start here
├── phases/                            # 4-phase workflow
│   ├── 01-research-analysis.md
│   ├── 02-planning.md
│   ├── 03-implementation.md
│   └── 04-resolution-verification.md
├── tools/                             # Tool references
│   ├── gh-pr-review-guide.md
│   ├── gh-review-conductor-guide.md
│   └── github-apis.md
├── patterns/                          # Workflow patterns
│   ├── parallel-workflow.md
│   └── interactive-workflow.md
└── templates/                         # Ready-to-use
    ├── shell-scripts/
    │   ├── automated-pr-resolution.sh
    │   ├── fetch-unresolved.sh
    │   └── resolve-threads.sh
    └── prompts/
        ├── research-prompt.md
        └── implementation-prompt.md
```

## Cheat Sheet

### Setup
```bash
gh extension install agynio/gh-pr-review
```

### One-Liner: Get Unresolved Count
```bash
gh pr-review review view -R owner/repo --pr 42 --unresolved | jq '[.reviews[].comments[]] | length'
```

### One-Liner: List Thread IDs
```bash
gh pr-review review view -R owner/repo --pr 42 --unresolved | jq -r '.reviews[].comments[].thread_id'
```

### One-Liner: Resolve All
```bash
gh pr-review review view -R owner/repo --pr 42 --unresolved | jq -r '.reviews[].comments[].thread_id' | xargs -I {} gh pr-review threads resolve 42 -R owner/repo --thread-id {}
```

## Tips

1. **Start small**: Process 3-5 threads at a time
2. **Test frequently**: Run tests after each change
3. **Commit atomically**: One thread = one commit
4. **Use filters**: `--unresolved --not_outdated` for current work
5. **Save output**: Pipe to JSON for later processing

## Next Steps

1. Read [[README]] for full overview
2. Pick a pattern based on your workflow
3. Follow the 4-phase approach
4. Use templates as starting points

## Support

- GitHub Issues: Report problems with the workflow
- Contribute: Add new patterns, tools, or improvements

---

[START_HERE]: START_HERE.md "Start Here: LLM-Driven PR Resolution"
[FRAMEWORK]: ../FRAMEWORK.md "Workflow Automation Framework"
[workflow-framework/README]: ../README.md "Workflow Automation Toolkit"
[README]: README.md "PR Comment Resolution Workflow"

[sequential-workflow]: ../_shared/patterns/sequential-workflow.md "Sequential PR Resolution Workflow"
[parallel-workflow]: ../_shared/patterns/parallel-workflow.md "Intra-PR Parallel Workflow"
[interactive-workflow]: ../_shared/patterns/interactive-workflow.md "Interactive Workflow Pattern"

[01-research-analysis]: ../_shared/phases/01-research-analysis.md "Phase 1: Research & Analysis"
[02-planning]: ../_shared/phases/02-planning.md "Phase 2: Planning"
[03-implementation]: ../_shared/phases/03-implementation.md "Phase 3: Implementation"
[04-resolution-verification]: ../_shared/phases/04-resolution-verification.md "Phase 4: Resolution & Verification"