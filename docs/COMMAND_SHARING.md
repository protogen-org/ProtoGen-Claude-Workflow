# Command Sharing and Personal Workflows

How to develop personal commands without affecting the team, and how to share improvements back.

## The Architecture

### Command Loading Order

Claude Code loads commands from multiple locations (highest priority first):

1. **Project-level**: `.claude/commands/` in the current repo
2. **Personal-level**: `~/.claude/commands/` (your global commands)

**Project-level wins** when the same command exists in both places.

### The Symlink Setup

Team members symlink their `~/.claude/commands/` to this repo:
```bash
~/.claude/commands/ → ProtoGen-Claude-Workflow/.claude/commands/
```

This means:
- All team commands are shared via this repo
- Changes you make locally affect the repo's working directory
- **Uncommitted changes are NOT pushed** - they stay local until you commit

---

## Developing Personal Commands

### Option 1: Project-Level Commands (Recommended)

Put experimental commands in your repo's `.claude/commands/`:

```bash
# In your testbed or personal repo
mkdir -p .claude/commands
touch .claude/commands/my-experiment.md
```

Benefits:
- Won't affect team workflows
- Specific to that repo
- Can iterate freely
- Project-level takes priority when working in that repo

### Option 2: Branches in This Repo

For larger experiments that might become team commands:

```bash
cd ~/repos/ProtoGen-Claude-Workflow
git checkout -b feature/andy-plan-issues
# Make changes
# Test locally
# Submit PR when ready
```

---

## Sharing Commands with the Team

### When to Share

Share a command when it:
- Solves a problem others have
- Works reliably (you've tested it)
- Isn't specific to your personal setup
- Follows team conventions

### How to Share (PR Workflow)

**This repo is Tier 0** - changes affect everyone's workflows. Follow these steps:

1. **Create a branch**
   ```bash
   cd ~/repos/ProtoGen-Claude-Workflow
   git checkout main
   git pull origin main
   git checkout -b feature/your-command-name
   ```

2. **Add or modify the command**
   ```bash
   # Copy from project-level if promoting
   cp ~/repos/your-repo/.claude/commands/my-command.md .claude/commands/

   # Or edit existing
   vim .claude/commands/existing-command.md
   ```

3. **Test in a Tier 2/3 repo first**
   - Don't test in production repos
   - Verify it works as expected
   - Check for edge cases

4. **Submit PR with context**
   - Explain what the command does
   - Why it's useful for the team
   - Any breaking changes to existing behavior
   - How you tested it

5. **Get team review**
   - Adam or Andy must approve Tier 0 changes
   - Address feedback before merging

6. **After merge, cleanup project-level copy**
   - Remove from your repo's `.claude/commands/` if it was there
   - Team version now takes over

---

## Avoiding Conflicts

### Don't Commit Directly to Main

```bash
# BAD - affects everyone immediately
git add .claude/commands/my-command.md
git commit -m "Add my command"
git push origin main  # DON'T DO THIS
```

### Do Use Branches and PRs

```bash
# GOOD - isolated until reviewed
git checkout -b feature/my-command
git add .claude/commands/my-command.md
git commit -m "feat: Add my-command for X purpose"
git push origin feature/my-command
# Create PR on GitHub
```

### Handling Uncommitted Changes

If you have uncommitted changes in the workflow repo:

```bash
cd ~/repos/ProtoGen-Claude-Workflow
git status

# Option A: Stash them (save for later)
git stash

# Option B: Move to a branch
git checkout -b feature/my-changes
git add .
git commit -m "WIP: my experimental changes"

# Option C: Discard if not needed
git restore .

# Option D: Move to project-level (recommended for personal stuff)
cp .claude/commands/my-command.md ~/repos/my-repo/.claude/commands/
git restore .claude/commands/my-command.md
```

---

## Quick Reference

| I want to... | Do this |
|--------------|---------|
| Experiment with a new command | Put it in your repo's `.claude/commands/` |
| Share a command with team | PR to this repo |
| Modify an existing team command | Branch → PR → Review |
| Test a team command change | Test in Tier 2/3 repo first |
| Keep my change local only | Use project-level or git stash |

---

## See Also

- [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md) - Tier system explained
- [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) - Full workflow documentation
- [SETUP_GUIDE.md](SETUP_GUIDE.md) - Initial setup instructions
