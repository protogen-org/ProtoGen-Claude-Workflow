# Command Reference

Detailed documentation for all GitHub Projects slash commands.

## Command Overview

| Command | Purpose | Modifies Data |
|---------|---------|---------------|
| `/project-status` | View board items | No |
| `/project-create` | Create new issue | Yes |
| `/project-update` | Update item fields | Yes |
| `/project-promote` | Move through stages | Yes |
| `/project-cicd` | Check CI/CD status | No |
| `/project-workflow` | Full workflow setup | Yes |

---

## /project-status

View items on the GitHub Project board grouped by status.

### Usage

```
/project-status [--stage <stage>] [--project <project>] [--type <type>]
```

### Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--stage` | dev, staging, production, all | all | Filter by deployment stage |
| `--project` | GRID, DASH, MAP, REOPT, DB, MGNAV | (all) | Filter by project |
| `--type` | feature, bug, hotfix, task | (all) | Filter by work type |

### Examples

```
# View all items
/project-status

# View only items in progress
/project-status --stage dev

# View Dashboard bugs
/project-status --project DASH --type bug

# View items ready for production
/project-status --stage production
```

### Output

Items are grouped by status and displayed in tables showing:
- Project prefix
- Work type
- Issue number
- Title
- Assignee
- Repository

---

## /project-create

Create a new GitHub issue and add it to the project board.

### Usage

```
/project-create
```

This command is interactive and prompts for required information.

### Prompts

1. **Type**: feature | bug | hotfix | task
2. **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
3. **Title**: Short description
4. **Description**: Full description
5. **Priority** (optional): P0 | P1 | P2 | P3
6. **Assignee** (optional): GitHub username

### Examples

```
# Start the creation workflow
/project-create

# Claude will prompt:
# Type? feature
# Project? GRID
# Title? Add user dashboard widget
# Description? Create a widget showing user activity metrics...
# Priority? P2
# Assignee? (leave blank or enter username)
```

### Behavior

- Creates issue in the appropriate repository
- Adds issue to Grid Nav project board
- Sets Status to "Backlog" (or "In Progress" for hotfixes)
- Sets Work Type, Project, and Priority fields
- Hotfixes automatically get P1 priority minimum

---

## /project-update

Update fields on an existing project board item.

### Usage

```
/project-update <issue> [options]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<issue>` | Yes | Issue number (e.g., 123 or #123) |

### Options

| Option | Values | Description |
|--------|--------|-------------|
| `--status` | See status values | New status |
| `--priority` | P0, P1, P2, P3 | New priority |
| `--type` | feature, bug, hotfix, task | Work type |
| `--environment` | dev, staging, main | Deployment environment |
| `--assignee` | GitHub username | Assign to user |

### Valid Status Values

- backlog, reported, triage, ready
- in_progress, review, qa
- fix_ready, verified, approved
- dev, staging, deploying, prod
- done, closed

### Examples

```
# Move issue to review
/project-update 123 --status review

# Change priority
/project-update 123 --priority P1

# Update multiple fields
/project-update 123 --status qa --environment staging

# Bulk update (comma-separated)
/project-update 123,124,125 --status review
```

---

## /project-promote

Move a project item to the next stage in the workflow.

### Usage

```
/project-promote <issue> [--stage <stage>] [--force]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `<issue>` | Yes | Issue number |

### Options

| Option | Description |
|--------|-------------|
| `--stage` | Target stage (auto-advances if not specified) |
| `--force` | Skip validation checks |

### Stage Progression

```
Backlog → Ready → In Progress → Review → QA → Approved → Done
```

### Validation

Before promoting past "Review", the command validates:
1. PR exists for the issue
2. PR has been merged
3. CI checks passed

Use `--force` to skip validation (not recommended).

### Examples

```
# Promote to next stage automatically
/project-promote 123

# Promote to specific stage
/project-promote 123 --stage qa

# Force promotion (skip validation)
/project-promote 123 --force
```

---

## /project-cicd

Check CI/CD pipeline status for PRs.

### Usage

```
/project-cicd [<issue>] [--branch <branch>] [--all]
```

### Arguments

All arguments are optional:

| Argument | Description |
|----------|-------------|
| `<issue>` | Check CI for specific issue's PRs |
| `--branch` | Check CI for specific branch |
| `--all` | Show all open PRs across repos |

### Examples

```
# Check CI for issue #123
/project-cicd 123

# Check CI for a branch
/project-cicd --branch feature/GRID-20260123-01-dashboard

# View all open PRs and their CI status
/project-cicd --all
```

### Output

Shows workflow status with:
- Workflow name
- Pass/Fail/Running status
- Duration
- Completion time

---

## /project-workflow

Start a complete workflow: create issue, branch, and update board.

### Usage

```
/project-workflow
```

This command is interactive and guides you through the full setup.

### Prompts

1. **Type**: feature | bugfix | hotfix
2. **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
3. **Title**: Short description
4. **Description**: Full description
5. **For bugfix**: Where was the bug found? (dev/staging)

### Automated Steps

1. Creates GitHub issue with labels
2. Adds issue to project board
3. Generates branch name following convention
4. Creates and checks out branch
5. Pushes branch with upstream tracking
6. Updates board status to "In Progress"
7. Adds comment to issue with branch info

### Branch Naming

```
<type>/<PROJECT>-<YYYYMMDD>-<##>-<description>
```

Examples:
- `feature/GRID-20260123-01-user-dashboard`
- `bugfix/DASH-20260123-02-date-picker`
- `hotfix/GRID-20260123-01-login-crash`

### Source Branch Selection

| Type | Source Branch |
|------|---------------|
| feature | dev |
| bugfix | dev (or staging if specified) |
| hotfix | main |

### Examples

```
# Start the workflow
/project-workflow

# Claude prompts for details, then:
# - Creates issue #123
# - Creates branch feature/GRID-20260123-01-dashboard
# - Updates project board
# - You're ready to code!
```

---

## Field Reference

### Status Options

| Status | ID | Description |
|--------|-----|-------------|
| Backlog | f75ad846 | Not started |
| Ready | 6b874b0c | Ready to start |
| In Progress | e18bf179 | Active work |
| Review | 47fc9ee4 | Code review |
| QA | aba860b9 | Quality testing |
| Approved | 90f6b26f | Approved |
| Done | f2fa8e41 | Complete |

### Work Type Options

| Type | ID |
|------|-----|
| Feature | 59fd994e |
| Bug | eb205d1e |
| Hotfix | 34f9f1af |
| Task | e6b93822 |

### Priority Options

| Priority | ID |
|----------|-----|
| P0 - Critical | 79628723 |
| P1 - High | 0a877460 |
| P2 - Medium | da944a9c |
| P3 - Low | 6b437f78 |

### Project Options

| Project | ID |
|---------|-----|
| Grid Nav | e044ed7f |
| Dash | dfbf1402 |
| Map | a7f9487f |
| REopt | 280b3eea |
| Database | d9a45ee7 |
| MGNav | e2284660 |
