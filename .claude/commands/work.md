---
description: Implement a GitHub issue autonomously - branch, code, test, PR
---

# Work on GitHub Issue

You are an experienced software engineer implementing a well-defined GitHub issue. The issue contains acceptance criteria and code references - use them as your guide.

## Input
- Issue: $ARGUMENTS (issue number, e.g., "123" or full URL)

## Exit Conditions (Check First)

**Do NOT continue if any of these are true:**
- Issue is already closed
- A PR was already merged for this issue
- Code already implements the acceptance criteria
- An open PR already exists for this issue

In these cases, report findings and exit gracefully.

## Process

### Step 1: Review the GitHub Issue

```bash
# Fetch issue details and state
gh issue view $ARGUMENTS --json number,state,title,body,comments
```

Extract and understand:
- Requirements and acceptance criteria
- Code references (implementation locations, related files, tests)
- Any discussion comments with additional context

### Step 2: Verify Work is Still Needed

Before implementing, confirm this work hasn't already been done:

```bash
# Check issue state - exit if closed
gh issue view $ARGUMENTS --json state --jq '.state'

# Check for existing PRs (open or merged) referencing this issue
gh pr list --state all --search "$ISSUE_NUMBER" --json number,state,title,headRefName --limit 5
```

**If the issue is CLOSED** or **a PR was already MERGED**, verify by checking the codebase:
- Look for key functions/patterns mentioned in the acceptance criteria
- If already implemented, exit and report: "Issue #X resolved by PR #Y. No work needed."

**If an open PR exists**, report: "PR #Y already open for this issue. Exiting."

### Step 3: Verify Branch Setup

Check the current branch status:
- If already on a feature branch for this issue, continue
- If on main/master/dev, create a new branch

Branch naming format: `feature/<repo>-<issue-number>-<brief-description>`

```bash
git branch --show-current
git checkout -b feature/<repo>-<issue-number>-<brief-description>
```

### Step 4: Quick Context Gathering

Only if the issue lacks sufficient code references:
- Identify the specific files that need modification
- Review existing patterns in similar code
- **Use MCP servers** (context7, holoviz) when documentation lookup is needed

Do not over-research. The issue should contain the guidance you need.

### Step 5: Implement

Work through the acceptance criteria systematically:
- Make changes following existing code patterns
- Commit frequently with clear messages referencing the issue (e.g., "Add validation (#489)")
- If you encounter something unexpected that changes the scope significantly, pause and ask

### Step 6: Test

- Run existing tests: `pytest` or the project's test command
- Write new tests as needed for the changes
- Ensure all tests pass before proceeding
- If tests fail, fix issues before continuing

### Step 7: Final Verification

Before creating the PR:
- [ ] All acceptance criteria met
- [ ] All tests passing
- [ ] Code follows project conventions
- [ ] No unintended changes (`git diff` is clean except for your work)

### Step 8: Create Pull Request

First, determine the correct base branch by finding where your feature branch diverged from:

```bash
# Detect base branch: dev → staging → main (check in order of preference)
BASE_BRANCH="main"

# Check if branch came from dev
if git merge-base --is-ancestor origin/dev HEAD 2>/dev/null; then
  DEV_BASE=$(git merge-base origin/dev HEAD)
  MAIN_BASE=$(git merge-base origin/main HEAD)
  if [ "$DEV_BASE" != "$MAIN_BASE" ]; then
    BASE_BRANCH="dev"
  fi
fi

# If not dev, check if branch came from staging
if [ "$BASE_BRANCH" = "main" ] && git merge-base --is-ancestor origin/staging HEAD 2>/dev/null; then
  STAGING_BASE=$(git merge-base origin/staging HEAD)
  MAIN_BASE=$(git merge-base origin/main HEAD)
  if [ "$STAGING_BASE" != "$MAIN_BASE" ]; then
    BASE_BRANCH="staging"
  fi
fi

echo "Creating PR against: $BASE_BRANCH"
```

Then create the PR:

```bash
gh pr create \
  --base $BASE_BRANCH \
  --title "Brief description of changes" \
  --assignee @me \
  --body "$(cat <<'EOF'
## Summary
[1-3 bullet points describing what this PR does]

## Changes
[List of key changes made]

## Testing
[How the changes were tested]

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated (if needed)
- [ ] No breaking changes (or documented if any)

Closes #[ISSUE_NUMBER]

---
Generated with [Claude Code](https://claude.ai/code)
EOF
)"
```

After creating the PR:
- Provide the PR URL
- Summarize what was implemented
- Note any follow-up items or deviations from the original issue

---

## Important Notes

- **Check before working**: Verify the issue is open and no PR exists before starting.
- **Trust the issue**: It contains acceptance criteria and code references. Don't re-plan what's already defined.
- **Move efficiently**: The goal is implementation, not analysis paralysis.
- **Pause if needed**: Only stop to ask if you encounter something that fundamentally changes the scope.
- **Test before PR**: Never create a PR with failing tests.
- **Target correct branch**: PRs should target the branch your feature branch was created from (dev → dev, staging → staging).

## Usage Examples

```
# By issue number (uses current repo)
/work 123

# By full URL
/work https://github.com/holoviz/panel/issues/456
```
