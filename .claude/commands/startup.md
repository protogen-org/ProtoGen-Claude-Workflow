# Start of Day

Help me get oriented for the day with a comprehensive status overview across my work.

## Tasks

### 1. GitHub Notifications
Check for unread notifications that need attention:
```bash
gh api notifications --jq '.[] | {reason, subject: .subject.title, repo: .repository.full_name}'
```
Summarize by type: mentions, review requests, CI failures, etc.

### 2. PRs Needing My Review
Find PRs where my review has been requested:
```bash
gh pr list --search "review-requested:@me" --limit 20
```

### 3. My Open PRs
Check status of PRs I've created:
```bash
gh pr list --author @me --state open
```
For each, note:
- Review status (approved, changes requested, pending)
- CI status (passing, failing, pending)
- Any new comments since yesterday

### 4. My Assigned Issues
Show open issues assigned to me:
```bash
gh issue list --assignee @me --state open --limit 30
```
Group by priority/labels if possible.

### 5. Work in Progress
If repo paths are provided, check each for:
- Current branch name
- Uncommitted changes (`git status --short`)
- Unpushed commits (`git log @{u}.. --oneline` if tracking branch exists)
- Any stashed work (`git stash list`)

### 6. Daily Priorities Summary
Provide a prioritized action list:

**🔴 Urgent**
- Failing CI on my PRs
- PRs with changes requested
- Issues labeled urgent/critical

**🟡 Reviews Needed**
- PRs awaiting my review (oldest first)

**🟢 Continue**
- My in-progress branches/PRs

**📋 Backlog**
- Assigned issues to pick up

## Quick Reference
**Claude workflow shortcuts:** `cc`, `ccw`, `ccw-clean`, `pstop`, `prv`, `pr-approve`, `pr-done`

## Arguments
$ARGUMENTS - Optional: space-separated paths to repos to check for WIP, or GitHub org/repo names to focus on
