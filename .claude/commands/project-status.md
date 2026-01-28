# Project Status Command

Display items on the GitHub Project board grouped by deployment stage.

## Usage

```
/project-status [--stage <stage>] [--project <project>] [--type <type>]
```

## Parameters (optional)

- `--stage`: Filter by stage (dev, staging, production, all). Default: all
- `--project`: Filter by project prefix (GRID, DASH, MAP, REOPT, DB, MGNAV)
- `--type`: Filter by type (feature, bug, hotfix, task)

## Instructions

### Step 1: Load Configuration

Look for `.claude-project-config.yml` in this order:
1. Current repo root: `./.claude-project-config.yml` (repo-specific override)
2. Workflow repo: `~/Documents/ProtoGen-Claude-Workflow/.claude-project-config.yml` (team default)
3. User home: `~/.claude-project-config.yml` (personal override)

Use the first file found. Parse it to get:
- `github.project.id` - Project board ID
- `github.fields.status.id` - Status field ID for filtering
- Repository mappings for display

If no config file exists, display error and stop.

### Step 2: Fetch Project Items

Run this GraphQL query to fetch project items:

```bash
gh api graphql -f query='
query {
  node(id: "PVT_kwDOC5eI7s4BK2oC") {
    ... on ProjectV2 {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue {
              number
              title
              state
              assignees(first: 3) {
                nodes { login }
              }
              repository {
                name
              }
            }
          }
          fieldValues(first: 20) {
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

### Step 3: Parse and Group Results

Parse the response and group results by Status field.

### Step 4: Display Results

Display as formatted tables grouped by status.

## Output Format

```
=== In Progress ===
| Project | Type    | Issue | Title                    | Assignee | Repo     |
|---------|---------|-------|--------------------------|----------|----------|
| GRID    | Feature | #123  | Add user dashboard       | Andy     | frontend |
| DASH    | Bug     | #125  | Fix date picker          | Adam     | Dashboard|

=== Review ===
| Project | Type    | Issue | Title                    | Assignee | Repo     |
|---------|---------|-------|--------------------------|----------|----------|
| GRID    | Feature | #120  | API rate limiting        | Aaron    | backend  |

=== QA ===
(no items)

=== Approved ===
| Project | Type    | Issue | Title                    | Assignee | Repo     |
|---------|---------|-------|--------------------------|----------|----------|
| DASH    | Feature | #118  | Export to CSV            | Adam     | Dashboard|

Total: 4 items across 3 stages
```

## Status Categories

Group items by these status values:
- **Backlog/Ready**: Not yet started
- **In Progress**: Active development
- **Review**: Code review stage
- **QA**: Quality assurance testing
- **Approved/Done**: Completed work
- **Staging/Prod**: Deployment tracking

## Error Handling

- If `gh` CLI is not authenticated, prompt user to run `gh auth login`
- If project scope is missing, prompt: `gh auth refresh -s project`
- If no items found, display "No items match the specified filters"
