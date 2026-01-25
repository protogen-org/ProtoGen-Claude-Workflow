# Promote Item to Next Stage

Move a project item to the next deployment stage in the workflow.

## Usage

```
/project-promote <issue> [--stage <stage>] [--force]
```

## Parameters

### Required
- `<issue>`: Issue number (e.g., 123 or #123)

### Optional
- `--stage`: Target stage (auto-advances to next if not specified)
- `--force`: Skip validation checks

## Stage Progression

### Work Status Progression
```
Backlog -> Ready -> In Progress -> Review -> QA -> Approved -> Done
```

### Environment Progression (Deployment)
```
Dev -> Staging -> Main (Production)
```

## Instructions

### Step 1: Fetch Current Item Status

```bash
# Get issue and its project item
gh api graphql -f query='
query {
  repository(owner: "protogen-org", name: "REPO") {
    issue(number: ISSUE_NUM) {
      id
      title
      state
      projectItems(first: 5) {
        nodes {
          id
          fieldValues(first: 10) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                name
                field { ... on ProjectV2SingleSelectField { name } }
              }
            }
          }
        }
      }
    }
  }
}'
```

### Step 2: Determine Next Stage

Based on current status, determine the next valid stage:

| Current Status | Next Status | Notes |
|---------------|-------------|-------|
| Backlog | Ready | Item is prioritized |
| Ready | In Progress | Work begins |
| In Progress | Review | PR created |
| Review | QA | PR approved |
| QA | Approved | Testing passed |
| Approved | Done | Work complete |

### Step 3: Validation Checks

Before promoting past "Review", verify:

1. **PR Exists**: Check for associated pull request
```bash
gh pr list --repo protogen-org/REPO --search "ISSUE_NUMBER in:body"
```

2. **PR Merged**: For promotion to QA or beyond
```bash
gh pr view PR_NUMBER --repo protogen-org/REPO --json state,merged
```

3. **CI Passed**: Check workflow status
```bash
gh run list --repo protogen-org/REPO --branch BRANCH_NAME --limit 1
```

### Step 4: Update Status

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    itemId: "ITEM_ID"
    fieldId: "PVTSSF_lADOC5eI7s4BK2oCzg6mc-0"
    value: { singleSelectOptionId: "NEW_STATUS_OPTION_ID" }
  }) {
    projectV2Item { id }
  }
}'
```

### Step 5: Add Comment

Document the promotion on the issue:

```bash
gh issue comment ISSUE_NUMBER --repo protogen-org/REPO \
  --body "Promoted to **QA** stage via Claude Code

Validation checks:
- PR #456 merged to dev branch
- CI checks passed
- Ready for QA testing"
```

## Environment Promotion

When promoting deployment stages (separate from work status):

```bash
# Update Environment field
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    itemId: "ITEM_ID"
    fieldId: "PVTSSF_lADOC5eI7s4BK2oCzg6me_U"
    value: { singleSelectOptionId: "ENVIRONMENT_OPTION_ID" }
  }) {
    projectV2Item { id }
  }
}'
```

## Output

```
Promoting issue #123: Add user dashboard widget

Current stage: Review
Target stage:  QA

Validation:
  [x] PR #456 exists
  [x] PR merged to dev
  [x] CI checks passed

Updating status... Done!

Issue #123 promoted to QA

Next steps:
  - QA team will test the changes
  - Use /project-promote 123 after QA approval to move to Approved
```

## Validation Failures

If validation fails, display what's missing:

```
Cannot promote issue #123 to QA

Validation failed:
  [ ] PR not merged - PR #456 is still open
  [x] CI checks passed

Options:
  1. Merge the PR first, then retry
  2. Use --force to skip validation (not recommended)
```

## Hotfix Handling

Hotfixes have expedited promotion:
- Can skip directly to appropriate stage
- Still require PR merge validation
- Auto-update environment to match target branch
