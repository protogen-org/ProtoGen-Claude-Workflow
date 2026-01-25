# Update Project Item

Update fields on an existing project board item.

## Usage

```
/project-update <issue> [--status <status>] [--priority <priority>] [--type <type>]
```

## Parameters

### Required
- `<issue>`: Issue number (e.g., 123 or #123) or issue URL

### Optional
- `--status`: New status value
- `--priority`: New priority (P0, P1, P2, P3)
- `--type`: Work type (feature, bug, hotfix, task)
- `--environment`: Deployment environment (dev, staging, main)
- `--assignee`: GitHub username to assign

## Valid Status Values

From `.claude-project-config.yml` (in workflow repo or current directory):
- backlog, reported, triage, ready
- in_progress, review, qa
- fix_ready, verified, approved
- dev, staging, deploying, prod
- done, closed

## Instructions

### Step 1: Find the Project Item

First, get the issue's node ID and find its project item:

```bash
# Get issue details
gh issue view ISSUE_NUMBER --repo protogen-org/REPO --json id,title,state

# Find project item ID
gh api graphql -f query='
query {
  node(id: "ISSUE_NODE_ID") {
    ... on Issue {
      projectItems(first: 10) {
        nodes {
          id
          project { title }
        }
      }
    }
  }
}'
```

### Step 2: Update the Field

Use the appropriate field ID and option ID from config:

```bash
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    itemId: "PROJECT_ITEM_ID"
    fieldId: "FIELD_ID"
    value: { singleSelectOptionId: "OPTION_ID" }
  }) {
    projectV2Item { id }
  }
}'
```

### Step 3: Add Comment (Optional)

If status changed, add a comment to the issue documenting the change:

```bash
gh issue comment ISSUE_NUMBER --repo protogen-org/REPO \
  --body "Status updated to **In Progress** via Claude Code"
```

## Field ID Reference

From `.claude-project-config.yml` (in workflow repo or current directory):

| Field | Field ID |
|-------|----------|
| Status | PVTSSF_lADOC5eI7s4BK2oCzg6mc-0 |
| Work Type | PVTSSF_lADOC5eI7s4BK2oCzg6mmNQ |
| Project | PVTSSF_lADOC5eI7s4BK2oCzg6med0 |
| Environment | PVTSSF_lADOC5eI7s4BK2oCzg6me_U |
| Priority | PVTSSF_lADOC5eI7s4BK2oCzg6mdrk |

## Workflow Validation

Before updating status, validate the transition is allowed:

**Allowed Transitions:**
- backlog -> ready, triage
- triage -> ready, backlog
- ready -> in_progress
- in_progress -> review
- review -> in_progress, qa (can go back for changes)
- qa -> review, approved
- approved -> done

If an invalid transition is requested, warn the user but allow override.

## Output

```
Updated issue #123: Add user dashboard widget

Changes:
  Status:   In Progress -> Review
  Priority: (unchanged)

Issue URL: https://github.com/protogen-org/ProtoGen-tools-frontend/issues/123
Board URL: https://github.com/orgs/protogen-org/projects/8
```

## Bulk Update

To update multiple issues, the user can provide comma-separated issue numbers:

```
/project-update 123,124,125 --status review
```

Process each issue sequentially and report results.

## Error Handling

- If issue not found, display error with search suggestions
- If issue not on project board, offer to add it
- If field value is invalid, show valid options
- If API call fails, display error details and retry suggestion
