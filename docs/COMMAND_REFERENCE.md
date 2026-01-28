# Command Reference

Complete reference for all slash commands and terminal functions in the ProtoGen Claude Workflow.

## Table of Contents

- [Slash Commands](#slash-commands)
  - [Issue & Workflow Commands](#issue--workflow-commands)
  - [GitHub Projects Commands](#github-projects-commands)
- [Terminal Functions](#terminal-functions)
- [Field Reference (GitHub Projects)](#field-reference-github-projects)

---

## Slash Commands

Slash commands run inside Claude Code sessions. Launch Claude Code with `cc`, then use these commands.

### Issue & Workflow Commands

#### `/issues` - Create GitHub Issues

Research a repository and create a well-structured GitHub issue following best practices.

```
/issues <description>
/issues repo: owner/repo <description>
```

**Behavior by tier:**
- **Tier 1 (Production)**: Full research + adds to GitHub Projects board
- **Tier 2 (Team Dev)**: Full research, labels only, no board
- **Tier 3 (Personal)**: Streamlined research, basic issue format
- **External**: Full research, follows target repo conventions

**Examples:**
```
/issues Add dark mode support to the settings page
/issues repo: holoviz/panel Add a disabled parameter to DatePicker
```

---

#### `/work` - Implement an Issue

Implement a GitHub issue autonomously: read issue, create branch, code, test, PR.

```
/work <issue#>
```

**What it does:**
1. Reads issue details from GitHub
2. Creates feature branch (if not already on one)
3. Implements changes following acceptance criteria
4. Runs tests
5. Creates pull request

**Example:**
```
/work 15
```

---

#### `/startup` - Start of Day

Get oriented for the day with a summary of what needs attention.

```
/startup
```

**Shows:**
- GitHub notifications needing attention
- PRs awaiting your review
- Your open PRs and their status
- Assigned issues
- Work in progress (uncommitted changes, unpushed commits)
- Prioritized action list

---

#### `/closedown` - End of Day

Wrap up your work with a summary of outstanding items.

```
/closedown
```

**Shows:**
- Uncommitted changes across repos
- Unpushed commits
- PRs needing attention
- Recommendations for what to handle before signing off

---

### GitHub Projects Commands

These commands integrate with the Grid Nav project board (#8). They're most useful in **Tier 1 repositories**.

#### `/project-status` - View Board Items

View items on the GitHub Project board grouped by status.

```
/project-status [--stage <stage>] [--project <project>] [--type <type>]
```

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--stage` | dev, staging, production, all | all | Filter by deployment stage |
| `--project` | GRID, DASH, MAP, REOPT, DB, MGNAV | (all) | Filter by project |
| `--type` | feature, bug, hotfix, task | (all) | Filter by work type |

**Examples:**
```
/project-status
/project-status --stage dev
/project-status --project DASH --type bug
/project-status --stage production
```

---

#### `/project-create` - Create Issue with Board Integration

Create a new GitHub issue and add it to the project board. Interactive command that prompts for details.

```
/project-create
```

**Prompts for:**
1. **Type**: feature | bug | hotfix | task
2. **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
3. **Title**: Short description
4. **Description**: Full description
5. **Priority** (optional): P0 | P1 | P2 | P3
6. **Assignee** (optional): GitHub username

**Behavior:**
- Creates issue in the appropriate repository
- Adds issue to Grid Nav project board
- Sets Status to "Backlog" (or "In Progress" for hotfixes)
- Sets Work Type, Project, and Priority fields
- Hotfixes automatically get P1 priority minimum

---

#### `/project-workflow` - Full Workflow Automation

Start a complete workflow: create issue, branch, and update board.

```
/project-workflow
```

**Prompts for:**
1. **Type**: feature | bugfix | hotfix
2. **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
3. **Title**: Short description
4. **Description**: Full description
5. **For bugfix**: Where was the bug found? (dev/staging)

**Automated steps:**
1. Creates GitHub issue with labels
2. Adds issue to project board
3. Generates branch name following convention
4. Creates and checks out branch
5. Pushes branch with upstream tracking
6. Updates board status to "In Progress"
7. Adds comment to issue with branch info

**Branch naming:**
```
<type>/<PROJECT>-<YYYYMMDD>-<##>-<description>
```

Examples:
- `feature/GRID-20260123-01-user-dashboard`
- `bugfix/DASH-20260123-02-date-picker`
- `hotfix/GRID-20260123-01-login-crash`

**Source branch selection:**

| Type | Source Branch |
|------|---------------|
| feature | dev |
| bugfix | dev (or staging if specified) |
| hotfix | main |

---

#### `/project-update` - Update Item Fields

Update fields on an existing project board item.

```
/project-update <issue> [options]
```

| Option | Values | Description |
|--------|--------|-------------|
| `--status` | See status values below | New status |
| `--priority` | P0, P1, P2, P3 | New priority |
| `--type` | feature, bug, hotfix, task | Work type |
| `--environment` | dev, staging, main | Deployment environment |
| `--assignee` | GitHub username | Assign to user |

**Valid status values:**
- backlog, reported, triage, ready
- in_progress, review, qa
- fix_ready, verified, approved
- dev, staging, deploying, prod
- done, closed

**Examples:**
```
/project-update 123 --status review
/project-update 123 --priority P1
/project-update 123 --status qa --environment staging
/project-update 123,124,125 --status review
```

---

#### `/project-promote` - Move Through Stages

Move a project item to the next stage in the workflow.

```
/project-promote <issue> [--stage <stage>] [--force]
```

| Option | Description |
|--------|-------------|
| `--stage` | Target stage (auto-advances if not specified) |
| `--force` | Skip validation checks |

**Stage progression:**
```
Backlog → Ready → In Progress → Review → QA → Approved → Done
```

**Validation:**
Before promoting past "Review", the command validates:
1. PR exists for the issue
2. PR has been merged
3. CI checks passed

Use `--force` to skip validation (not recommended).

**Examples:**
```
/project-promote 123
/project-promote 123 --stage qa
/project-promote 123 --force
```

---

#### `/project-cicd` - Check CI/CD Status

Check CI/CD pipeline status for PRs.

```
/project-cicd [<issue>] [--branch <branch>] [--all]
```

| Argument | Description |
|----------|-------------|
| `<issue>` | Check CI for specific issue's PRs |
| `--branch` | Check CI for specific branch |
| `--all` | Show all open PRs across repos |

**Examples:**
```
/project-cicd 123
/project-cicd --branch feature/GRID-20260123-01-dashboard
/project-cicd --all
```

---

## Terminal Functions

These functions run in your terminal (PowerShell or Bash), not inside Claude Code.

### `cc` - Launch Claude Code

Launch Claude Code in permissionless mode.

```bash
cc
```

Use this to start a Claude Code session where you can run slash commands.

---

### `ccw <issue#>` - Work in Worktree

Create an isolated worktree for an issue and launch Claude Code.

```bash
ccw 15
```

**What it does:**
1. Fetches issue title from GitHub
2. Creates new branch: `feature/myrepo-15-add-dark-mode`
3. Creates worktree at: `~/Documents/worktrees/myrepo-issue15/`
4. Copies `.env` files to the worktree
5. Launches Claude Code with `/work 15`

**When to use:**
- Long-running implementations
- Working on multiple issues in parallel
- Keeping main repo clean while experimenting

---

### `prv [pr#]` - Verify PR

Prepare a PR for manual verification.

```bash
prv              # List all open PRs
prv 15           # Checkout and prepare PR #15
```

**What it does:**
1. Shows PR title and files changed
2. Checks out the PR (or switches to its worktree)
3. Activates conda environment from `environment.yml`
4. Runs `pip install -e .` for editable install
5. Shows command to run the application

---

### `pr-done <pr#>` - Merge and Clean Up

Approve, merge, and clean up a PR.

```bash
pr-done 15
```

**What it does:**
1. Cleans up worktree (if one exists)
2. Approves the PR (skipped if it's your own)
3. Merges with squash
4. Deletes remote branch
5. Returns to `main` and pulls latest

---

### `pstop` - Stop Running Servers

Kill any running Panel/dashboard server processes.

```bash
pstop
```

Use before merging or when you need to free up ports.

---

### `ccw-clean` - Manage Worktrees

Clean up git worktrees.

```bash
ccw-clean -List              # Show all worktrees
ccw-clean 15                 # Remove worktree for issue #15
ccw-clean -All               # Remove ALL worktrees
ccw-clean -All -Repo myrepo  # Remove all worktrees for a specific repo
```

---

## Field Reference (GitHub Projects)

Reference IDs for the Grid Nav project board fields. Used internally by `/project-*` commands.

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

---

## Quick Reference Table

| Command | Where | Description |
|---------|-------|-------------|
| `cc` | Terminal | Launch Claude Code |
| `/issues <desc>` | Claude Code | Create GitHub issue |
| `/work <issue#>` | Claude Code | Implement issue |
| `ccw <issue#>` | Terminal | Worktree + implement |
| `prv [pr#]` | Terminal | Verify PR |
| `pstop` | Terminal | Stop servers |
| `pr-done <pr#>` | Terminal | Merge and clean up |
| `ccw-clean` | Terminal | Manage worktrees |
| `/startup` | Claude Code | Start of day |
| `/closedown` | Claude Code | End of day |
| `/project-status` | Claude Code | View board |
| `/project-create` | Claude Code | Create issue + board |
| `/project-workflow` | Claude Code | Full automation |
| `/project-update` | Claude Code | Update fields |
| `/project-promote` | Claude Code | Advance stage |
| `/project-cicd` | Claude Code | Check CI/CD |
