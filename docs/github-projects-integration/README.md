# GitHub Projects Integration for Claude Code

> **Version**: 1.0.0
> **Status**: Active
> **Last Updated**: 2026-01-23

This integration enables the ProtoGen team to manage GitHub Projects directly through Claude Code, streamlining workflow management across all ProtoGen repositories.

## Overview

The GitHub Projects integration provides Claude Code with:

1. **Project Board Access** - View and update items on the Grid Nav project board
2. **Workflow Automation** - Create issues, branches, and track work through deployment stages
3. **CI/CD Visibility** - Check pipeline status for PRs and branches
4. **Consistent Naming** - Enforce branch naming conventions automatically

## Architecture

```
ProtoGen-Specs/
├── CLAUDE.md                    # Claude Code context and instructions
├── .claude-project-config.yml   # Project IDs, field mappings, workflow rules
├── .claude/
│   └── commands/                # Slash command definitions
│       ├── project-status.md    # View board by stage
│       ├── project-create.md    # Create issues
│       ├── project-update.md    # Update item fields
│       ├── project-promote.md   # Move items through stages
│       ├── project-cicd.md      # Check CI/CD status
│       └── project-workflow.md  # Full workflow automation
└── docs/
    └── github-projects-integration/
        ├── README.md            # This file
        ├── GETTING_STARTED.md   # Onboarding guide
        ├── COMMAND_REFERENCE.md # Detailed command docs
        └── TROUBLESHOOTING.md   # Common issues
```

## How It Works

### Configuration-Driven

All project board IDs, field IDs, and option IDs are stored in `.claude-project-config.yml`. This allows:
- Easy updates when board structure changes
- Single source of truth for all repositories
- No hardcoded IDs in command definitions

### GraphQL API

The integration uses GitHub's GraphQL API via the `gh` CLI:
- Read operations fetch board items and field values
- Write operations update item fields and create issues
- All API calls are authenticated through your `gh` CLI session

### Workflow Alignment

Commands are designed around ProtoGen's existing workflow:
- **Branch Strategy**: feature/bugfix/hotfix from appropriate source branches
- **Status Progression**: Backlog → In Progress → Review → QA → Approved → Done
- **Deployment Pipeline**: dev → staging → main

## Target Project Board

**Grid Nav** (#8) - The primary development board for ProtoGen

| Field | Purpose |
|-------|---------|
| Status | Work progress tracking |
| Work Type | Feature, Bug, Hotfix, Task, Deployment |
| Project | Grid Nav, Dash, Map, REopt, Database, MGNav |
| Environment | Dev, Staging, Main |
| Priority | P0 (Critical) through P3 (Low) |

## Repositories Covered

| Repository | Project Prefix | Description |
|------------|---------------|-------------|
| ProtoGen-tools-frontend | GRID | React frontend |
| ProtoGen-tools-backend | GRID | Flask API |
| Dashboard | DASH | Panel Material UI |
| Protogen-tools-map | MAP | Mapping tool |
| ProtoGen-REopt-Engine | REOPT | REopt engine |
| ProtoGen-Specs | SPEC | Specifications |

## Quick Start

1. Ensure `gh` CLI has project scope: `gh auth refresh -s project`
2. Pull latest ProtoGen-Specs
3. Test with `/project-status` command
4. See [GETTING_STARTED.md](./GETTING_STARTED.md) for full onboarding

## Available Commands

| Command | Purpose |
|---------|---------|
| `/project-status` | View items grouped by deployment stage |
| `/project-create` | Create feature/bugfix/hotfix issues |
| `/project-update` | Update item status or fields |
| `/project-promote` | Move items through workflow stages |
| `/project-cicd` | Check CI/CD pipeline status |
| `/project-workflow` | Start complete workflow (issue + branch + board) |

## Documentation

- **[GETTING_STARTED.md](./GETTING_STARTED.md)** - Team onboarding checklist
- **[COMMAND_REFERENCE.md](./COMMAND_REFERENCE.md)** - Detailed command documentation
- **[TROUBLESHOOTING.md](./TROUBLESHOOTING.md)** - Common issues and solutions

## Security Notes

- Configuration file contains project IDs (not secrets) - safe to commit
- All API calls use your `gh` CLI authentication
- No credentials stored in repository
- Token scopes required: `project`, `repo`, `read:org`

## Contributing

To update the integration:

1. Create a feature branch from `dev`
2. Update configuration or command files
3. Test changes thoroughly
4. Create PR with documentation updates
5. Coordinate team notification after merge
