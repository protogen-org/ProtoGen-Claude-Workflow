# ProtoGen Claude Code Workflow

Team-wide Claude Code workflow configuration, slash commands, and automation scripts for ProtoGen development.

## Overview

This repository provides a unified Claude Code workflow for the ProtoGen team, combining:
- **Slash commands** for issue management, GitHub Projects integration, and workflow automation
- **PowerShell and Bash scripts** for development workflow functions
- **Configuration templates** for consistent team setup
- **Documentation** for onboarding and troubleshooting

## Four-Tier Workflow System

ProtoGen repositories use tiered automation based on collaboration requirements:

| Tier | Description | Workflow | Repositories |
|------|-------------|----------|--------------|
| **0** | Workflow Infrastructure | PR required, team review, explicit confirmation | ProtoGen-Claude-Workflow |
| **1** | Production (Board) | Full `/project-*` commands, PR required | frontend, backend, Dashboard, map, REopt-Engine |
| **2** | Team Dev Tools | `/issues` + `/work`, PRs recommended | batch_reopt, sandbox_dash, circuit_viz, pv_viz |
| **3** | Personal/Infra | Direct commits OK, basic git hygiene | Personal repos, legacy tools, infrastructure |

### Why Different Workflows?

**Production code repos** (Tier 1) use the full `dev→staging→main` pipeline because code deployments need staged testing environments, CI/CD validation, and rollback capability. Each environment corresponds to a real deployment target.

**Documentation and configuration repos** (Tier 2/3) use simplified `feature→main` workflows because these repos don't deploy to environments—changes take effect when merged. The extra branches would add overhead without benefit. The simplified flow still requires PRs and review, maintaining quality without unnecessary complexity.

This is intentional: **match workflow complexity to deployment complexity**.

### Tier 0: Special Handling

**This repository (ProtoGen-Claude-Workflow) is Tier 0.** Changes here affect the entire team's workflow. When working in this repo:

- All changes require PRs with team review
- Claude should ask for explicit confirmation before modifying slash commands
- Test changes in Tier 2/3 repos before applying to production
- Document rollback procedures for significant changes

See [Migration Guide](docs/MIGRATION_GUIDE.md) for complete tier documentation and safeguards.

## Quick Start

### Prerequisites

- [Claude Code](https://claude.ai/code) installed (`npm install -g @anthropic-ai/claude-code`)
- [GitHub CLI](https://cli.github.com/) installed and authenticated
- PowerShell (Windows) or Bash (Linux/macOS)
- Conda/Anaconda (for Python environment management)

### Installation

**1. Clone this repository:**

```bash
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git
cd ProtoGen-Claude-Workflow
```

**2. Set up slash commands:**

Create a symbolic link from your global Claude commands directory to this repository:

**Windows (PowerShell - run as Administrator):**
```powershell
New-Item -ItemType SymbolicLink `
    -Path "$env:USERPROFILE\.claude\commands" `
    -Target "$PWD\.claude\commands"
```

**Linux/macOS (Bash):**
```bash
ln -s "$(pwd)/.claude/commands" "$HOME/.claude/commands"
```

**3. Set up workflow scripts:**

Add to your shell profile to load the workflow functions on startup.

**Windows - PowerShell Profile** (`$PROFILE` or `Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`):
```powershell
# Source ProtoGen Claude workflow
. "$env:USERPROFILE\Documents\ProtoGen-Claude-Workflow\scripts\powershell\claude-aliases.ps1"
```

**Linux/macOS - Bash Profile** (`~/.bashrc` or `~/.bash_profile`):
```bash
# Source ProtoGen Claude workflow
source "$HOME/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"
```

**4. Set up MCP servers (optional but recommended):**

See [docs/MCP_SERVERS.md](docs/MCP_SERVERS.md) for team-standard MCP server configuration.

**5. Restart your terminal** and verify setup:

```bash
# You should see workflow functions loaded
cc --help
```

## What's Included

### Slash Commands

Global commands available in any Claude Code session:

**Issue & Workflow Management:**
- `/issues` - Create well-structured GitHub issues with research and best practices
- `/work` - Implement a GitHub issue autonomously (branch, code, test, PR)
- `/startup` - Start of day overview (notifications, PRs, assigned issues)
- `/closedown` - End of day summary (uncommitted changes, unpushed commits)

**GitHub Projects Integration:**
- `/project-status` - View project board filtered by status/type
- `/project-create` - Create issues with automatic board integration
- `/project-workflow` - Complete workflow automation (issue → branch → board update)
- `/project-update` - Update item fields with validation
- `/project-promote` - Move items through deployment stages
- `/project-cicd` - Check CI/CD pipeline status

> **Note:** GitHub Projects commands use `.claude-project-config.yml` for board configuration. The default config (Grid Nav project) is in this repo. Individual repositories can override by placing their own config file in the repo root.

### Workflow Functions

**PowerShell (Windows):**
- `cc` - Launch Claude Code in permissionless mode
- `ccw <issue#>` - Create git worktree for issue and launch Claude
- `prv [pr#]` - Checkout and verify PR (install dependencies, activate env)
- `pr-done <pr#>` - Approve, merge, and clean up PR
- `pstop` - Stop running Panel/dashboard servers
- `ccw-clean` - Manage git worktrees

**Bash (Linux/macOS):**
- Same functions as PowerShell, adapted for Unix environments

### Templates

- `.claude.json.template` - Team-standard MCP servers and settings
- `powershell-profile.ps1.template` - PowerShell profile setup example
- `bash-profile.sh.template` - Bash profile setup example

### Documentation

- [Setup Guide](docs/SETUP_GUIDE.md) - Detailed setup instructions for Windows and Linux
- [Workflow Guide](docs/WORKFLOW_GUIDE.md) - Complete development workflow with **Mermaid flowcharts** for the development lifecycle, bug origin decisions, and understanding commits/pushes/PRs
- [Command Reference](docs/COMMAND_REFERENCE.md) - All commands with examples
- [MCP Servers](docs/MCP_SERVERS.md) - Team-standard MCP server configuration
- [Migration Guide](docs/MIGRATION_GUIDE.md) - Migrate from existing setups, includes **tier decision flowchart**
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions

## Repository Structure

```
ProtoGen-Claude-Workflow/
├── README.md                          # This file
├── .gitignore                         # Git ignore patterns
├── .claude-project-config.yml         # GitHub Projects configuration (Grid Nav)
├── .claude/
│   └── commands/                      # Slash commands (*.md files)
│       ├── issues.md
│       ├── work.md
│       ├── startup.md
│       ├── closedown.md
│       ├── project-status.md
│       ├── project-create.md
│       ├── project-workflow.md
│       ├── project-update.md
│       ├── project-promote.md
│       └── project-cicd.md
├── scripts/
│   ├── powershell/
│   │   └── claude-aliases.ps1        # PowerShell workflow functions
│   └── bash/
│       └── claude-aliases.sh         # Bash workflow functions
├── templates/
│   ├── .claude.json.template         # MCP servers and settings template
│   ├── powershell-profile.ps1.template
│   └── bash-profile.sh.template
└── docs/
    ├── SETUP_GUIDE.md                # Platform-specific setup
    ├── WORKFLOW_GUIDE.md             # Development workflow
    ├── COMMAND_REFERENCE.md          # All commands with examples
    ├── MCP_SERVERS.md                # MCP server setup
    ├── MIGRATION_GUIDE.md            # Migrate from existing setup
    └── TROUBLESHOOTING.md            # Common issues
```

## Development Workflow Example

Here's a typical workflow using these tools:

```bash
# 1. Start of day - see what needs attention
cc
> /startup

# 2. Create an issue for new work
> /issues Add dark mode support to the dashboard

# 3. Implement the issue in a worktree (parallel work)
ccw 42

# 4. (Claude implements the feature, runs tests, creates PR)

# 5. Verify the PR
prv 42
# Test the changes in browser...

# 6. Merge and clean up
pstop
pr-done 42

# 7. End of day summary
cc
> /closedown
```

## Team Members

- **Adam Morse** - Original workflow development (PowerShell, slash commands)
- **Andy Mackey** - GitHub Projects integration (GraphQL, project management)
- **Aaron Trebing** - QA and workflow refinement

## Contributing

This repository is for ProtoGen team use. To propose changes:

1. Create a feature branch
2. Test your changes locally
3. Create a PR with clear description
4. Get review from at least one team member

## Support

- **Issues:** Use [GitHub Issues](https://github.com/protogen-org/ProtoGen-Claude-Workflow/issues)
- **Documentation:** See [docs/](docs/) directory
- **Questions:** Ask in team chat or create a discussion

## Related Repositories

- [ProtoGen-Specs](https://github.com/protogen-org/ProtoGen-Specs) - Project specifications and architecture
- [ProtoGen-tools-frontend](https://github.com/protogen-org/ProtoGen-tools-frontend) - React frontend
- [ProtoGen-tools-backend](https://github.com/protogen-org/ProtoGen-tools-backend) - Flask backend
- [Dashboard](https://github.com/protogen-org/Dashboard) - ProtoGen Dashboard (Panel)
- [sandbox_dash](https://github.com/protogen-org/sandbox_dash) - Sandbox Dashboard (Panel)
- [circuit_viz](https://github.com/protogen-org/circuit-viz) - Circuit Visualization (Panel)
- [batch_reopt](https://github.com/protogen-org/batch_reopt) - Batch ReOpt tool (Panel)

## License

Internal use only - ProtoGen team members.
