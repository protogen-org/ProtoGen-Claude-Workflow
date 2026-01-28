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

Loaded from `.claude-project-config.yml`:
- backlog, reported, triage, ready
- in_progress, review, qa
- fix_ready, verified, approved
- dev, staging, deploying, prod
- done, closed

## Instructions

### Step 0: Load Configuration

Look for `.claude-project-config.yml` in this order:
1. Current repo root: `./.claude-project-config.yml` (repo-specific override)
2. Workflow repo: `~/Documents/ProtoGen-Claude-Workflow/.claude-project-config.yml` (team default)
3. User home: `~/.claude-project-config.yml` (personal override)

Use the first file found. Parse it to get:
- `github.project.id` - Project board ID
- `github.fields.status.id` and `.options` - Status field configuration
- `github.fields.work_type.id` and `.options` - Work type configuration
- `github.fields.project.id` and `.options` - Project area configuration
- `github.fields.priority.id` and `.options` - Priority configuration
- `github.fields.environment.id` and `.options` - Environment configuration

If no config file exists, display error and stop.

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

Field IDs are loaded from `.claude-project-config.yml`:
- `github.fields.status.id` - Status field
- `github.fields.work_type.id` - Work Type field
- `github.fields.project.id` - Project area field
- `github.fields.environment.id` - Environment field
- `github.fields.priority.id` - Priority field

Use these IDs from the loaded config when making GraphQL mutations.

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
