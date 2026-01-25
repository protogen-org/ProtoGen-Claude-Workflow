# End of Day Closedown

Help me wrap up my work for the day by providing a comprehensive status summary and ensuring nothing is left uncommitted or unpushed.

## Tasks

### 1. Git Status Check
If repo paths are provided, check each repository for:

**For each repo, run:**
```bash
git -C <repo_path> status --short
git -C <repo_path> branch --show-current
git -C <repo_path> log @{u}.. --oneline 2>/dev/null || echo "No upstream tracking"
git -C <repo_path> stash list
```

Report:
- Current branch
- Uncommitted changes (modified, staged, untracked files)
- Unpushed commits
- Stashed work that might be forgotten

### 2. My Open PRs Status
Check PRs I've created:
```bash
gh pr list --author @me --state open
```
For each, note if there are:
- Pending reviews
- Failed checks
- Merge conflicts
- Comments I haven't responded to

### 3. PRs Awaiting My Review
Show PRs where review was requested but I haven't reviewed:
```bash
gh pr list --search "review-requested:@me"
```

### 4. My Assigned Issues
Quick view of open issues:
```bash
gh issue list --assignee @me --state open --limit 20
```

### 5. Today's Activity (Optional)
If possible, summarize what was accomplished:
- Commits made today
- PRs opened/merged/reviewed
- Issues closed

### 6. Closedown Summary
Provide a clear status report:

**✅ Clean Repos**
- Repos with no uncommitted changes, fully pushed

**⚠️ Uncommitted Work**
- Repos with changes that need committing
- List the files/changes briefly

**📤 Unpushed Commits**
- Repos with local commits not yet pushed
- Show commit subjects

**🔍 PRs Needing Attention**
- My PRs that need responses or fixes
- Reviews I still owe

**📋 Open Issues**
- Count of assigned issues carrying to tomorrow

### 7. Recommendations
Suggest specific actions if needed:
- "Consider committing changes in X repo"
- "You have unpushed commits in Y - push or they may be lost"
- "PR #123 has failing CI - may want to fix before EOD"

## Arguments
$ARGUMENTS - Optional: space-separated paths to repos to check, e.g., ~/projects/repo1 ~/projects/repo2
