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
- **Title**: Short description of the work
- **Description**: Full description of work to be done

## Optional Parameters

Ask the user for these (they can skip if not applicable):
- **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
  - Auto-detected from current repository if not specified
  - User can override the default (e.g., change GRID to DB for database work in tools-backend)
- **Priority**: P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low). Default: P2
- **Environment**: dev | staging | main | feature | bugfix | hotfix. Default: dev
  - Helps track which branch/environment the work targets
  - For hotfixes: Automatically set to "main"
- **Bug Type**: ui | api | data | database | other
  - **Only ask if Type is "bug"** (not relevant for features/tasks/hotfixes)
  - Helps categorize bugs for debugging and metrics
- **Assignee**: GitHub username

## Project Auto-Detection

If the user does not specify a Project, detect it from the current repository:

| Current Repository | Default Project |
|--------------------|-----------------|
| Dashboard | DASH |
| ProtoGen-tools-frontend | GRID |
| ProtoGen-tools-backend | GRID |
| ProtoGen-MGNav-backend | MGNAV |
| ProtoGen-REopt-Engine | REOPT |
| Protogen-tools-map | MAP |
| ProtoGen-Specs | SPEC |

Inform the user of the detected default and allow them to override if needed.

## Project Prefix to Field Mapping

The project prefix determines BOTH the repository AND the Project field value on the board:

| Project Prefix | Project Field Value | Repository | Notes |
|----------------|---------------------|------------|-------|
| GRID | Grid Nav | ProtoGen-tools-frontend | React UI for Grid Nav |
| GRID | Grid Nav | ProtoGen-tools-backend | Flask API for Grid Nav |
| DASH | Dash | Dashboard | Panel Material UI dashboard |
| MAP | Map | Protogen-tools-map | Mapping tool |
| REOPT | REopt | ProtoGen-REopt-Engine | REopt engine |
| DB | Database | ProtoGen-tools-backend | Database infrastructure work |
| MGNAV | MGNav | ProtoGen-MGNav-backend | Public MGNav product |
| SPEC | Grid Nav | ProtoGen-Specs | Specifications (typically Grid Nav) |

### Distinguishing Grid Nav Frontend vs Backend

**GRID prefix applies to BOTH repositories** - always ask the user which one:

**ProtoGen-tools-frontend** (React/TypeScript):
- UI components, forms, pages, layouts
- User interactions, client-side validation
- React hooks, state management, context
- Styling, CSS, Material-UI components
- Client-side routing, navigation
- Example: "Add PV configuration form", "Fix date picker styling", "Update dashboard layout"

**ProtoGen-tools-backend** (Flask/Python):
- API endpoints, routes, controllers
- Business logic, calculations, algorithms
- REopt integration, payload building (system_builder)
- Database queries, models, ORM
- Authentication, authorization, sessions
- Background jobs, data processing
- Example: "Add average outage algorithm", "Fix REopt payload validation", "Update tariff API"

**Always ask**: "Is this a frontend (UI) or backend (API/logic) issue?"

### Multiple Project Areas, Same Repository

**ProtoGen-tools-backend** serves multiple project areas with different Project field values:
- **GRID** → Project field: "Grid Nav" (system_builder, REopt, core Grid Nav API)
- **DB** → Project field: "Database" (infrastructure, migrations, schema changes)
- **MGNAV** → Project field: "MGNav" (Public MGNav-specific features)

**When the user specifies backend**, ask which project area to set the correct field.

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

Based on the project prefix, select the appropriate repository from the mapping table above.

**For GRID (Grid Nav)**: Always ask the user whether this is a frontend or backend issue:
- Use the guidance in "Distinguishing Grid Nav Frontend vs Backend" section above
- Frontend → `ProtoGen-tools-frontend`
- Backend → `ProtoGen-tools-backend`

**For backend issues (tools-backend repo)**: If the user specified backend, ask which project area:
- GRID (Grid Nav system work) → Project field: "Grid Nav"
- DB (Database infrastructure) → Project field: "Database"
- MGNAV (Public MGNav) → Project field: "MGNav"

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

Set these fields using the field IDs and option IDs from the loaded config:

**Always set these**:
- **Work Type**: Based on type parameter (feature→Feature, bug→Bug, hotfix→Hotfix, task→Task)
  - Use `github.fields.work_type.id` and `.options` from config
- **Project**: Based on project parameter using the "Project Field Value" column from the mapping table above:
  - GRID → "Grid Nav" (grid_nav option)
  - DASH → "Dash" (dash option)
  - MAP → "Map" (map option)
  - REOPT → "REopt" (reopt option)
  - DB → "Database" (database option)
  - MGNAV → "MGNav" (mgnav option)
  - SPEC → "Grid Nav" (grid_nav option)
  - Use `github.fields.project.id` and `.options` from config
- **Priority**: Based on priority parameter (default P2 - Medium)
  - P0 → p0_critical, P1 → p1_high, P2 → p2_medium, P3 → p3_low
  - Use `github.fields.priority.id` and `.options` from config
- **Status**: Set to "Backlog" (or "In Progress" for hotfixes)
  - Use `github.fields.status.id` and `.options.backlog` or `.options.in_progress` from config

**Set if provided by user**:
- **Environment**: If user specified (dev, staging, main, feature, bugfix, hotfix)
  - Use `github.fields.environment.id` and `.options` from config
  - dev → dev, staging → staging, main → main, feature → feature, bugfix → bugfix, hotfix → hotfix
- **Bug Type**: If user specified AND Type is "bug" (ui, api, data, database, other)
  - Use `github.fields.bug_type.id` and `.options` from config
  - ui → ui, api → api, data → data, database → database, other → other

## Hotfix Special Handling

For hotfixes:
- Set Priority to P1 (High) automatically unless P0 specified
- Set Status to "In Progress" (skip Backlog)
- Set Environment to "main" (production hotfix)
- Remind user: hotfix branches come from `main`, merge to main/staging/dev

## Output

```
Issue created successfully!

  Issue: #123
  Title: [Feature] Add user dashboard widget
  Repo:  protogen-org/ProtoGen-tools-frontend
  URL:   https://github.com/protogen-org/ProtoGen-tools-frontend/issues/123

Project board updated:
  Status:      Backlog
  Type:        Feature
  Project:     Grid Nav
  Priority:    P2 - Medium
  Environment: dev (if specified)
  Bug Type:    (not applicable for features)

Next steps:
  1. Create branch: feature/GRID-20260123-01-user-dashboard-widget
  2. Or use /project-workflow to automate branch creation
```

## Error Handling

- Validate project prefix is recognized
- Check gh CLI authentication before proceeding
- If issue creation fails, display error and do not attempt board update
- If board update fails, display issue URL and manual instructions
