# Start New Work Workflow

Initialize a complete workflow: create issue, set up branch, update board.

## Usage

```
/project-workflow
```

This command is interactive and will guide you through the workflow setup.

## Parameters

The command will prompt for:
- **Type**: feature | bugfix | hotfix
- **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
- **Title**: Short description
- **Description**: Full description of work

## Automated Steps

### Step 1: Create Issue

Use the `/project-create` logic to:
- Create GitHub issue with proper labels
- Add to project board
- Set initial status based on type

### Step 2: Generate Branch Name

Format: `<type>/<PROJECT>-<YYYYMMDD>-<##>-<short-description>`

```bash
# Get today's date
DATE=$(date +%Y%m%d)

# Find existing branches for today to determine sequence number
EXISTING=$(git branch -a | grep -c "$TYPE/$PROJECT-$DATE" || echo 0)
SEQ=$(printf "%02d" $((EXISTING + 1)))

# Generate branch name
BRANCH="$TYPE/$PROJECT-$DATE-$SEQ-$DESCRIPTION"
```

Examples:
- `feature/GRID-20260123-01-user-dashboard`
- `bugfix/DASH-20260123-02-date-picker`
- `hotfix/GRID-20260123-01-login-crash`

### Step 3: Determine Source Branch

| Type | Source Branch | Notes |
|------|---------------|-------|
| feature | dev | New functionality |
| bugfix | dev | Default for bugs |
| bugfix | staging | If bug found in staging |
| hotfix | main | Critical production fix |

For bugfix, ask user where the bug was found.

### Step 4: Create and Checkout Branch

```bash
# Fetch latest
git fetch origin

# Create branch from source
git checkout -b BRANCH_NAME origin/SOURCE_BRANCH

# Push branch to set upstream
git push -u origin BRANCH_NAME
```

### Step 5: Update Project Board

Set fields on the project item:
- **Status**: "In Progress" (skip Backlog for workflow-initiated items)
- **Environment**: Based on source branch (dev/staging/main)

### Step 6: Link Branch to Issue

Add a comment to the issue with branch information:

```bash
gh issue comment ISSUE_NUMBER --repo protogen-org/REPO \
  --body "Branch created: \`$BRANCH_NAME\`

Development started via Claude Code workflow.

**Source branch:** $SOURCE_BRANCH
**Target branch:** $TARGET_BRANCH"
```

## Output Summary

```
Workflow initialized successfully!

Issue Created:
  Number: #123
  Title:  [Feature] Add user dashboard widget
  URL:    https://github.com/protogen-org/ProtoGen-tools-frontend/issues/123

Branch Created:
  Name:   feature/GRID-20260123-01-user-dashboard
  Source: dev
  Target: dev (for PR)

Project Board Updated:
  Status:      In Progress
  Type:        Feature
  Project:     Grid Nav
  Environment: Dev

You are now on branch: feature/GRID-20260123-01-user-dashboard

Next steps:
  1. Make your code changes
  2. Commit with message referencing #123
     Example: git commit -m "Add dashboard widget component

     Implements user activity metrics display.
     Relates to #123"
  3. Push changes: git push
  4. Create PR: gh pr create --base dev
  5. After PR approval, use: /project-promote 123
```

## Hotfix Special Handling

For hotfixes:
1. Source branch is always `main`
2. Priority auto-set to P1 (High) minimum
3. Status set directly to "In Progress"
4. Remind user about merge targets:

```
HOTFIX WORKFLOW

This is a hotfix branch. After the fix:
  1. Create PR to main (primary)
  2. After main merge, cherry-pick or create PRs to:
     - staging
     - dev

Use /project-promote with --hotfix flag to track all merges.
```

## Repository Context

If run from within a ProtoGen repository, auto-detect:
- Current repository for issue creation
- Appropriate project prefix

```bash
# Detect current repo
REPO=$(basename $(git remote get-url origin) .git)

# Map to project prefix
case $REPO in
  ProtoGen-tools-frontend|ProtoGen-tools-backend) PROJECT="GRID" ;;
  Dashboard) PROJECT="DASH" ;;
  Protogen-tools-map) PROJECT="MAP" ;;
  ProtoGen-REopt-Engine) PROJECT="REOPT" ;;
  ProtoGen-Specs) PROJECT="SPEC" ;;
esac
```

## Abort Workflow

If the user cancels at any point:
- If issue was created, keep it (don't delete)
- If branch was created, offer to delete it
- Display what was completed and what wasn't

## Error Recovery

If any step fails:
1. Display what succeeded
2. Display what failed with error details
3. Provide manual commands to complete remaining steps

```
Workflow partially completed:

  [x] Issue #123 created
  [x] Added to project board
  [ ] Branch creation failed: permission denied

To complete manually:
  git checkout -b feature/GRID-20260123-01-user-dashboard origin/dev
  git push -u origin feature/GRID-20260123-01-user-dashboard
```
