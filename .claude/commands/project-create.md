# Create Project Item

Create a new GitHub issue with proper typing and add to the project board.

## Usage

```
/project-create
```

This command is interactive - it will prompt for required information.

## Required Parameters

Ask the user for:
- **Type**: feature | bug | hotfix | task
- **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
- **Title**: Short description of the work
- **Description**: Full description of work to be done

## Optional Parameters

- **Priority**: P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low). Default: P2
- **Assignee**: GitHub username

## Repository Mapping

| Project | Repository | Notes |
|---------|------------|-------|
| GRID | ProtoGen-tools-frontend | React frontend |
| GRID | ProtoGen-tools-backend | Flask API (default for GRID) |
| DASH | Dashboard | Panel Material UI |
| MAP | Protogen-tools-map | Mapping tool |
| REOPT | ProtoGen-REopt-Engine | REopt engine |
| DB | ProtoGen-tools-backend | Database work |
| MGNAV | ProtoGen-tools-backend | Public MGNav |
| SPEC | ProtoGen-Specs | Specifications |

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

If no config file exists, display an error message:
```
Error: .claude-project-config.yml not found

Please ensure the ProtoGen-Claude-Workflow repository is set up:
  ~/Documents/ProtoGen-Claude-Workflow/.claude-project-config.yml

Or create a repo-specific override in the current directory.
```

### Step 1: Determine Repository

Based on the project prefix, select the appropriate repository from the mapping above.
For GRID, ask user if frontend or backend.

### Step 2: Create the Issue

```bash
gh issue create \
  --repo protogen-org/REPOSITORY \
  --title "[TYPE] TITLE" \
  --body "DESCRIPTION" \
  --label "type:TYPE" \
  --label "project:PROJECT"
```

Example:
```bash
gh issue create \
  --repo protogen-org/ProtoGen-tools-frontend \
  --title "[Feature] Add user dashboard widget" \
  --body "Add a new dashboard widget that displays user activity metrics.

## Acceptance Criteria
- Widget shows daily active users
- Widget shows session duration
- Responsive on mobile" \
  --label "type:feature" \
  --label "project:grid-nav"
```

### Step 3: Add to Project Board

Get the issue node ID and add to project:

```bash
# Get issue node ID
ISSUE_ID=$(gh issue view ISSUE_NUMBER --repo protogen-org/REPO --json id -q .id)

# Add to project
gh api graphql -f query='
mutation {
  addProjectV2ItemById(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    contentId: "'$ISSUE_ID'"
  }) {
    item { id }
  }
}'
```

### Step 4: Set Project Fields

Use the field IDs from the loaded config file to set fields:

```bash
# Get the project item ID from Step 3 response, then:
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    itemId: "ITEM_ID"
    fieldId: "PVTSSF_lADOC5eI7s4BK2oCzg6mmNQ"
    value: { singleSelectOptionId: "WORK_TYPE_OPTION_ID" }
  }) {
    projectV2Item { id }
  }
}'
```

Set these fields:
- **Work Type**: Based on type parameter
- **Project**: Based on project parameter
- **Priority**: Based on priority parameter (default P2)
- **Status**: Set to "Backlog" (or "In Progress" for hotfixes)

## Hotfix Special Handling

For hotfixes:
- Set Priority to P1 (High) automatically unless P0 specified
- Set Status to "In Progress" (skip Backlog)
- Remind user: hotfix branches come from `main`, merge to main/staging/dev

## Output

```
Issue created successfully!

  Issue: #123
  Title: [Feature] Add user dashboard widget
  Repo:  protogen-org/ProtoGen-tools-frontend
  URL:   https://github.com/protogen-org/ProtoGen-tools-frontend/issues/123

Project board updated:
  Status:   Backlog
  Type:     Feature
  Project:  Grid Nav
  Priority: P2 - Medium

Next steps:
  1. Create branch: feature/GRID-20260123-01-user-dashboard-widget
  2. Or use /project-workflow to automate branch creation
```

## Error Handling

- Validate project prefix is recognized
- Check gh CLI authentication before proceeding
- If issue creation fails, display error and do not attempt board update
- If board update fails, display issue URL and manual instructions
