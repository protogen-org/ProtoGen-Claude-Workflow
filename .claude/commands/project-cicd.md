# Check CI/CD Status

Display CI/CD pipeline status for PRs related to project items.

## Usage

```
/project-cicd [<issue>] [--branch <branch>] [--all]
```

## Parameters

All parameters are optional:
- `<issue>`: Specific issue number to check
- `--branch`: Branch name to check directly
- `--all`: Show all open PRs with CI status across ProtoGen repos

## Instructions

### Option 1: Check Specific Issue

If an issue number is provided:

```bash
# Find PRs that reference this issue
gh pr list --repo protogen-org/REPO --search "ISSUE_NUMBER" --json number,title,headRefName,state

# Get CI status for each PR
gh pr checks PR_NUMBER --repo protogen-org/REPO
```

### Option 2: Check Specific Branch

If a branch name is provided:

```bash
# Get workflow runs for the branch
gh run list --repo protogen-org/REPO --branch BRANCH_NAME --limit 5

# Get detailed status
gh run view RUN_ID --repo protogen-org/REPO
```

### Option 3: Check All Open PRs

If `--all` is specified, check across all ProtoGen repositories:

```bash
# For each repository in the config
for repo in ProtoGen-tools-frontend ProtoGen-tools-backend Dashboard Protogen-tools-map; do
  gh pr list --repo protogen-org/$repo --state open --json number,title,headRefName
done
```

## Output Format

### Single Issue

```
Issue #123: Add user dashboard widget
Branch: feature/GRID-20260123-01-user-dashboard
PR: #456 (open)

CI/CD Status:
| Workflow              | Status    | Duration | Completed    |
|-----------------------|-----------|----------|--------------|
| Test Integration      | Pass      | 2m 34s   | 5 mins ago   |
| Build                 | Pass      | 1m 12s   | 5 mins ago   |
| Lint & Type Check     | Pass      | 45s      | 5 mins ago   |
| Deploy Preview        | Running   | -        | In progress  |

Overall: 3/4 checks passed, 1 in progress

PR URL: https://github.com/protogen-org/ProtoGen-tools-frontend/pull/456
```

### All Open PRs

```
=== ProtoGen-tools-frontend ===
| PR   | Title                    | Branch                              | CI Status |
|------|--------------------------|-------------------------------------|-----------|
| #456 | Add user dashboard       | feature/GRID-20260123-01-dashboard  | Passing   |
| #458 | Fix login redirect       | bugfix/GRID-20260123-02-login       | Failing   |

=== ProtoGen-tools-backend ===
| PR   | Title                    | Branch                              | CI Status |
|------|--------------------------|-------------------------------------|-----------|
| #234 | API rate limiting        | feature/GRID-20260122-01-rate-limit | Passing   |

=== Dashboard ===
(no open PRs)

Summary: 3 open PRs (2 passing, 1 failing)
```

## Status Indicators

Use these indicators in output:
- `Pass` - All checks passed
- `Fail` - One or more checks failed
- `Running` - Checks in progress
- `Pending` - Checks not yet started
- `Skipped` - Checks were skipped

## Detailed Failure Information

When a check fails, show details:

```
FAILED: Test Integration

  Run ID: 12345678
  Started: 10 mins ago
  Duration: 3m 45s

  Error summary:
    tests/test_dashboard.py::test_user_widget FAILED
    AssertionError: Expected 5 widgets, got 4

  View full logs:
    gh run view 12345678 --repo protogen-org/ProtoGen-tools-frontend --log
```

## Quick Actions

After displaying status, suggest relevant actions:

```
Quick actions:
  - View PR: gh pr view 456 --repo protogen-org/ProtoGen-tools-frontend
  - View logs: gh run view 12345678 --log
  - Re-run failed: gh run rerun 12345678 --failed
  - Merge PR: gh pr merge 456 --squash
```

## Repository Detection

If run from within a ProtoGen repository, auto-detect the repo:

```bash
# Get current repo from git remote
git remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/'
```

## Error Handling

- If no PRs found for issue, suggest checking branch name
- If gh CLI not authenticated, prompt for login
- If rate limited, display wait time and suggest caching
