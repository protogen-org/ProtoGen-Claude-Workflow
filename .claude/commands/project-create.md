# Create Project Item

Quick issue creation for project management - creates a GitHub issue and adds it to the project board with minimal friction.

**Use this for**: Quick captures, PM task logging, simple issues that don't need research.

**Use `/issues` instead for**: Well-researched issues with duplicate checking, code references, and detailed acceptance criteria.

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

Use the field IDs from `.claude-project-config.yml` (in workflow repo or current directory) to set fields:

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

## Related Commands

- `/issues` - Full research-driven issue creation (duplicate check, code refs, detailed structure)
- `/project-workflow` - Start working on an issue (creates branch, updates status)
