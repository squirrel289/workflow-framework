# gh-review-conductor Tool Guide

Interactive terminal UI for PR review workflows. Best for manual, human-driven review processes.

## When to Use

**Good for:**
- Interactive preview and application of code suggestions
- Visual browsing of review comments
- Bulk suggestion application with user confirmation
- Fuzzy matching for outdated suggestion hunks

**Not ideal for:**
- Fully automated, reproducible workflows
- LLM-driven resolution (use `gh-pr-review` instead)
- Programmatic thread resolution
- CI/CD integration

## Installation

```bash
# Install the extension
gh extension install gh-tui-tools/gh-review-conductor

# Verify installation
gh review-conductor --version

# Update
gh extension upgrade gh-tui-tools/gh-review-conductor
```

## Core Commands

### 1. List Comments (`list`)

Fetch and display review comments.

```bash
# List all comments for current PR
gh review-conductor list

# List for specific PR
gh review-conductor list 42

# List specific thread
gh review-conductor list 42 THREAD_ID

# Include resolved comments
gh review-conductor list --all

# JSON output
gh review-conductor list --json
```

### 2. Browse Comments (`browse`)

Interactive TUI for navigating comments.

```bash
# Launch interactive browser
gh review-conductor browse

# Jump to specific comment
gh review-conductor browse COMMENT_ID

# Open comment in browser
gh review-conductor browse --open COMMENT_ID
```

**TUI Navigation:**
- `↑/↓` - Navigate comments
- `Enter` - View details
- `o` - Open in browser
- `q` - Quit

### 3. Apply Suggestions (`apply`)

Preview and apply code suggestions interactively.

```bash
# Interactive mode (recommended)
gh review-conductor apply

# Apply all suggestions without prompts
gh review-conductor apply --all

# Apply suggestions in specific file
gh review-conductor apply --file src/auth.py

# Include resolved threads
gh review-conductor apply --include-resolved

# Enable AI-assisted fuzzy matching
gh review-conductor apply --ai-auto

# Debug mode
gh review-conductor apply --debug
```

**Interactive prompts:**
- Review each suggestion individually
- Preview diff before applying
- Accept, skip, or reject changes

### 4. Resolve Threads (`resolve`)

Mark threads as resolved interactively.

```bash
# Resolve specific thread
gh review-conductor resolve COMMENT_ID

# Resolve all threads
gh review-conductor resolve --all

# Unresolve thread
gh review-conductor resolve COMMENT_ID --unresolve
```

### 5. Comment/Reply (`comment`)

Add replies to review threads.

```bash
# Reply via editor
gh review-conductor comment COMMENT_ID

# Inline body
gh review-conductor comment COMMENT_ID --body "Fixed in abc123"

# From file
gh review-conductor comment COMMENT_ID --body-file message.txt

# From stdin
echo "Fixed" | gh review-conductor comment COMMENT_ID

# Resolve after commenting
gh review-conductor comment COMMENT_ID --resolve
```

## Interactive Workflow Example

### Scenario: Apply all suggestions

```bash
# 1. Browse comments to understand scope
gh review-conductor browse

# 2. List unresolved comments
gh review-conductor list

# 3. Apply suggestions interactively
gh review-conductor apply

# Interactive prompts appear:
# ┌─────────────────────────────────────┐
# │ Suggestion in src/auth.py:42       │
# │ "Add error handling"                │
# │                                     │
# │ [a]ccept [s]kip [r]eject [q]uit    │
# └─────────────────────────────────────┘

# 4. Review changes
git diff

# 5. Commit if satisfied
git add .
git commit -m "Applied review suggestions"

# 6. Resolve threads
gh review-conductor resolve --all
```

## AI-Assisted Application

For outdated or fuzzy suggestions:

```bash
# Enable AI assistance
gh review-conductor apply --ai-auto \
  --ai-provider openai \
  --ai-model gpt-4 \
  --ai-token $OPENAI_API_KEY
```

**Supported providers:**
- OpenAI (GPT-4, GPT-3.5)
- Anthropic (Claude)
- Custom endpoints

## Options Reference

### Color Control

```bash
# Disable colors, emojis, hyperlinks
gh review-conductor --no-color <command>

# Or set environment variable
export NO_COLOR=1
gh review-conductor list
```

### Debug Mode

```bash
# Verbose logging
gh review-conductor apply --debug
```

## Use Cases

### 1. Batch Suggestion Application

```bash
# Review all suggestions, apply good ones
gh review-conductor apply
# (interactive prompts for each)

# Or trust and apply all
gh review-conductor apply --all
```

### 2. Manual Review Process

```bash
# Browse → Review → Apply → Comment → Resolve
gh review-conductor browse
gh review-conductor apply
gh review-conductor comment COMMENT_ID --body "Done"
gh review-conductor resolve COMMENT_ID
```

### 3. Selective File Updates

```bash
# Apply suggestions only in auth.py
gh review-conductor apply --file src/auth.py
```

## Limitations

**Not suitable for:**
- Scripted/automated workflows (no JSON output for apply)
- LLM agent integration (requires human interaction)
- Parallel processing (interactive TUI is sequential)
- CI/CD pipelines (requires terminal interaction)

**Better alternatives for automation:**
- Use `gh-pr-review` for programmatic workflows
- Use GitHub APIs directly for CI/CD integration

## Tips

### Keep Working Tree Clean

```bash
# Stash changes before applying suggestions
git stash

# Apply suggestions
gh review-conductor apply --all

# Review changes
git diff

# Commit or stash again
git commit -am "Apply review suggestions"
```

### Preview Before Accepting

Always review diffs in the interactive prompts. The TUI shows:
- Old code (red)
- New code (green)
- Context lines (unchanged)

### Combine with gh-pr-review

```bash
# Use gh-pr-review for data gathering
gh pr-review review view -R owner/repo --pr 42 --unresolved > threads.json

# Use gh-review-conductor for interactive application
gh review-conductor apply --all

# Use gh-pr-review for programmatic resolution
cat threads.json | jq -r '.reviews[].comments[].thread_id' | \
  xargs -I {} gh pr-review threads resolve 42 -R owner/repo --thread-id {}
```

## Reference

- [Official README](https://github.com/gh-tui-tools/gh-review-conductor)
- [[gh-pr-review-guide]] - For programmatic workflows

---

[gh-pr-review-guide]: gh-pr-review-guide.md "gh-pr-review Tool Guide"