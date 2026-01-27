# Migration Guide

Migrate to the unified ProtoGen Claude Workflow from various existing setups.

## Overview: Four-Tier Workflow System

ProtoGen repositories use tiered automation based on collaboration requirements and deployment sensitivity. Understanding which tier a repository belongs to determines which workflow commands and processes apply.

---

## Workflow Tiers

### Tier 0: Meta/Workflow Infrastructure (SPECIAL HANDLING)

**The workflow system itself - changes affect everyone.**

| Repository | Description |
|------------|-------------|
| ProtoGen-Claude-Workflow | Slash commands, scripts, workflow configuration |

#### Why Tier 0 is Special

Changes to this repository affect how Claude behaves across ALL other repositories:
- Modifications to slash commands change team-wide behavior
- Mistakes propagate to every developer
- Claude may have "false confidence" and break intended workflows
- This repo defines the rules Claude follows everywhere else

#### Tier 0 Requirements

- **PR REQUIRED** for all changes (no direct commits to main)
- **Team review required** - Adam or Andy must approve
- **Test changes locally first** before pushing
- **Document the "why"** - explain reasoning in commit messages
- **Include rollback instructions** for significant changes

#### Claude Behavior in Tier 0

When working in ProtoGen-Claude-Workflow, Claude should:

1. **Announce the tier**: "This is the Tier 0 workflow repo - I'll be extra careful with changes."

2. **Before modifying ANY slash command**:
   - Ask: "This change to `/command-name` will affect how the command works across all repos. Should I proceed?"
   - Explain what repos/workflows will be affected
   - Get explicit approval before making the change

3. **Before modifying configuration files** (`.claude-project-config.yml`, etc.):
   - List what fields/IDs are changing
   - Explain the impact on existing workflows
   - Verify the change doesn't break Tier 1 repos

4. **For documentation changes**:
   - Verify accuracy against actual command behavior
   - Don't document features that don't exist yet
   - Update all related docs when changing one

5. **Testing requirements**:
   - Describe how the change should be tested
   - Suggest testing in a Tier 2/3 repo first before production repos

6. **Rollback documentation**:
   - For significant changes, document how to undo them
   - Keep changes incremental so rollback is feasible

---

### Tier 1: Full GitHub Projects Workflow

**Production repositories on the Grid Nav Board (#8) - collaboration with Pegasus One/Suhail.**

| Repository | Description |
|------------|-------------|
| ProtoGen-tools-frontend | React frontend application |
| ProtoGen-tools-backend | Flask backend API |
| ProtoGen-tools-Dashboard | Panel dashboard |
| Protogen-tools-map | Mapping tool |
| ProtoGen-REopt-Engine | Julia optimization engine |
| ProtoGen-Specs | Project specifications |

#### Tier 1 Workflow

- **Full `/project-*` commands** - status, create, workflow, update, promote, cicd
- **Board status tracking** - Items tracked through Todo → In Progress → In Review → Done
- **PR requirements** - All changes via pull requests
- **Deployment pipeline** - dev → staging → main branches
- **Issue linking** - All work tied to GitHub issues

#### Available Commands

```bash
/project-status          # View board items by status
/project-create          # Quick issue creation with board integration
/project-workflow        # Full automation: issue → branch → board
/project-update          # Update item fields
/project-promote         # Move through deployment stages
/project-cicd            # Check CI/CD pipeline status
/issues                  # Research-driven issue creation (prompts for Tier 1)
/work                    # Implement an issue autonomously
```

---

### Tier 2: Simplified Team Workflow

**Team development tools NOT on the project board - shared experimentation.**

| Repository | Description |
|------------|-------------|
| batch_reopt | Batch ReOpt simulations |
| sandbox_dash | Panel Material UI sandbox |
| circuit_viz | Circuit visualization |
| pv_viz | Solar resource analysis dashboard |

#### Tier 2 Workflow

- **Use `/issues` and `/work`** - `/issues` will prompt for tier and skip board integration when Tier 2 is selected
- **Simpler branch strategy** - feature branches, but less formal
- **PRs recommended** but not mandatory for all changes
- **No board tracking** - work tracked via issues only

#### Available Commands

```bash
/issues                  # Create GitHub issues
/work                    # Implement issue (branch, code, test, PR)
/startup                 # Daily overview
/closedown               # End of day summary
```

---

### Tier 3: Minimal/Direct Workflow

**Personal, infrastructure, and specialized repositories.**

#### Andy's Repos

| Repository | Description |
|------------|-------------|
| pgnode1-server | Photogrammetry/infrastructure |
| reopt-testbed-react | Personal development sandbox |

#### Adam's Repos / Legacy Tools

| Repository | Description |
|------------|-------------|
| mpc_optimizer | MPC battery dispatch optimizer |
| postgres-etl-pipeline | ETL pipeline development |
| electricity-bills-etl-pipeline | Bills ETL processing |
| load-curve-analysis-dashboard | Load curve analysis |
| comprehensive-dashboard | Analysis dashboard |
| comstock-athena | BuildStock/AWS Athena exploration |
| xendee_export | Xendee CSV parser |
| helper-scripts | Reusable utility scripts |

#### Aaron's / Team Specialized Repos

| Repository | Description |
|------------|-------------|
| protogen-database-migrations | Database migration tracking |
| ProtoGen-MGNav-frontend-react | MGNav frontend |
| ProtoGen-MGNav-backend | MGNav backend |
| ProtoGen-Internal-admin-frontend-react | Internal admin tools |
| ProtoGen-Internal-admin-backend | Internal admin backend |

#### Learning/LMS Repos

| Repository | Description |
|------------|-------------|
| ProtoGen-Learning | Moodle LMS |
| ESAMTAC-Moodle | ESAMTAC LMS |
| Moodle-Plugin | Custom Moodle plugin |

#### Tier 3 Workflow

- **Direct commits to main/master allowed**
- **No board tracking**
- **Basic git hygiene only** - meaningful commit messages, don't break things
- **`/issues` available** - select Tier 3 when prompted for streamlined issue creation (minimal research, basic format)

---

## Migration Scenarios

### Scenario 1: Fresh Install (No Existing Setup)

Follow the [Setup Guide](SETUP_GUIDE.md) directly. No migration needed.

### Scenario 2: From Dropbox-Based Workflow

If you were using Adam's original Dropbox-synced workflow:

**1. Identify your current setup:**
```bash
# Check if using Dropbox path
ls -la ~/.claude/commands 2>/dev/null || echo "No commands symlink"
cat ~/.bashrc | grep -i dropbox || echo "No Dropbox references in bashrc"
```

**2. Backup existing commands:**
```bash
# If symlink exists
[ -L ~/.claude/commands ] && mv ~/.claude/commands ~/.claude/commands.backup.dropbox
# If directory exists
[ -d ~/.claude/commands ] && mv ~/.claude/commands ~/.claude/commands.backup.dropbox
```

**3. Clone the workflow repo:**
```bash
cd ~/repos  # or your preferred location
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git
```

**4. Create new symlink:**
```bash
ln -s ~/repos/ProtoGen-Claude-Workflow/.claude/commands ~/.claude/commands
```

**5. Update shell profile:**

Remove old Dropbox references and add:
```bash
# ProtoGen Claude Workflow
CLAUDE_WORKFLOW_PATH="$HOME/repos/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"
if [ -f "$CLAUDE_WORKFLOW_PATH" ]; then
    source "$CLAUDE_WORKFLOW_PATH"
fi
```

### Scenario 3: From Local .claude/commands Setup

If you have local command files (not symlinked):

**1. Backup your commands:**
```bash
mv ~/.claude/commands ~/.claude/commands.backup.local
```

**2. Clone and symlink:**
```bash
cd ~/repos
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git
ln -s ~/repos/ProtoGen-Claude-Workflow/.claude/commands ~/.claude/commands
```

**3. Review your backup:**

Check `~/.claude/commands.backup.local` for any custom commands you want to preserve. Custom commands can be added to the workflow repo via PR.

### Scenario 4: From ProtoGen-Specs-Based Commands

If you were using slash commands from ProtoGen-Specs (Andy's original setup):

**1. Verify current setup:**
```bash
ls -la ~/.claude/commands
# Should show symlink to ProtoGen-Specs/.claude/commands
```

**2. Update symlink target:**
```bash
rm ~/.claude/commands
cd ~/repos
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git
ln -s ~/repos/ProtoGen-Claude-Workflow/.claude/commands ~/.claude/commands
```

**3. Pull latest ProtoGen-Specs:**
```bash
cd ~/repos/ProtoGen-Specs
git checkout main
git pull origin main
```

The commands have been moved from ProtoGen-Specs to ProtoGen-Claude-Workflow. ProtoGen-Specs now focuses on specifications only.

---

## Platform-Specific Setup

### Windows (PowerShell)

**1. Clone repository:**
```powershell
cd $env:USERPROFILE\repos
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git
```

**2. Create symlink (Run as Administrator):**
```powershell
# Remove existing if present
if (Test-Path "$env:USERPROFILE\.claude\commands") {
    Remove-Item "$env:USERPROFILE\.claude\commands" -Recurse -Force
}

# Create symlink
New-Item -ItemType SymbolicLink `
    -Path "$env:USERPROFILE\.claude\commands" `
    -Target "$env:USERPROFILE\repos\ProtoGen-Claude-Workflow\.claude\commands"
```

**3. Update PowerShell profile:**

Add to `$PROFILE` (usually `Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`):
```powershell
# ProtoGen Claude Workflow
$ClaudeWorkflowPath = "$env:USERPROFILE\repos\ProtoGen-Claude-Workflow\scripts\powershell\claude-aliases.ps1"
if (Test-Path $ClaudeWorkflowPath) {
    . $ClaudeWorkflowPath
}
```

**4. Reload profile:**
```powershell
. $PROFILE
```

### Linux/macOS (Bash)

**1. Clone repository:**
```bash
cd ~/repos  # or /home/amack/repos on pgnode1
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git
```

**2. Backup and create symlink:**
```bash
# Backup if exists
[ -e ~/.claude/commands ] && mv ~/.claude/commands ~/.claude/commands.backup

# Create parent directory if needed
mkdir -p ~/.claude

# Create symlink
ln -s ~/repos/ProtoGen-Claude-Workflow/.claude/commands ~/.claude/commands
```

**3. Update bash profile:**

Add to `~/.bashrc`:
```bash
# ProtoGen Claude Workflow
CLAUDE_WORKFLOW_PATH="$HOME/repos/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"
if [ -f "$CLAUDE_WORKFLOW_PATH" ]; then
    source "$CLAUDE_WORKFLOW_PATH"
fi
```

**4. Reload profile:**
```bash
source ~/.bashrc
```

---

## Determining Your Workflow Tier

Use this decision tree for any repository:

```
Is it ProtoGen-Claude-Workflow?
├── YES → Tier 0 (SPECIAL - PR required, team review, explicit confirmation)
└── NO → Continue...
    │
    Is it on the Grid Nav Board (#8)?
    ├── YES → Tier 1 (Full GitHub Projects workflow)
    │   Repos: frontend, backend, Dashboard, map, REopt-Engine, Specs
    └── NO → Continue...
        │
        Is it a shared team dev tool?
        ├── YES → Tier 2 (Simplified workflow)
        │   Repos: batch_reopt, sandbox_dash, circuit_viz, pv_viz
        └── NO → Tier 3 (Minimal workflow)
            Personal, infrastructure, legacy, specialized repos
```

---

## Verification Checklist

After migration, verify your setup:

### Commands Symlink
```bash
ls -la ~/.claude/commands
# Should show: commands -> /path/to/ProtoGen-Claude-Workflow/.claude/commands
```

### Workflow Functions Loaded
```bash
type cc
# Should show: cc is a function (or alias)
```

### Test Tier Detection

**Tier 0 (Workflow Repo):**
```bash
cd ~/repos/ProtoGen-Claude-Workflow
cc
# Claude should announce special handling for Tier 0
```

**Tier 1 (Production Repo):**
```bash
cd ~/repos/ProtoGen-tools-Dashboard
cc
> /project-status
# Should show board items
```

**Tier 2 (Team Dev Tool):**
```bash
cd ~/repos/batch_reopt
cc
> /work
# Should work without board integration
```

**Tier 3 (Personal Repo):**
```bash
cd ~/repos/pgnode1-server
# Direct commits work, no special workflow required
```

---

## Rollback Procedure

If you need to revert to your previous setup:

### Restore Commands
```bash
# Remove new symlink
rm ~/.claude/commands

# Restore backup
[ -d ~/.claude/commands.backup ] && mv ~/.claude/commands.backup ~/.claude/commands
```

### Restore Shell Profile

Edit `~/.bashrc` or PowerShell profile to remove the workflow sourcing lines and restore any previous configuration.

### Restore Repo State (if needed)
```bash
# If you need to go back to using ProtoGen-Specs commands
cd ~/repos/ProtoGen-Specs
git checkout feature/SPEC-20260123-01-github-projects-integration
ln -s ~/repos/ProtoGen-Specs/.claude/commands ~/.claude/commands
```

---

## Troubleshooting

### Commands Not Found

**Symptom:** `/project-status` or other commands not recognized

**Solution:**
```bash
# Verify symlink
ls -la ~/.claude/commands

# Should point to workflow repo
# If broken, recreate:
rm ~/.claude/commands
ln -s ~/repos/ProtoGen-Claude-Workflow/.claude/commands ~/.claude/commands
```

### Workflow Functions Not Loaded

**Symptom:** `cc` command not found

**Solution:**
```bash
# Check if sourced in profile
grep -i "claude-aliases" ~/.bashrc

# If missing, add the source line and reload
source ~/.bashrc
```

### Permission Denied on Symlink

**Windows:** Run PowerShell as Administrator to create symlinks.

**Linux/macOS:** Ensure you have write permissions to `~/.claude/`

### Board Commands Fail

**Symptom:** `/project-status` returns errors

**Solution:**
1. Verify you're in a Tier 1 repository
2. Check `.claude-project-config.yml` exists and has correct project ID
3. Verify GitHub CLI is authenticated: `gh auth status`

---

## Future Enhancements

Planned improvements to discuss with the team:

1. **Automatic tier detection** - Slash commands detect tier based on repo
2. **Tier 0 CLAUDE.md** - Explicit safeguard instructions in workflow repo
3. **Environment-specific prompts** - Different behavior for dev/staging/main
4. **Issue type templates** - Customized for features, bugs, hotfixes per tier
5. **pgnode1 infrastructure docs** - Document photogrammetry/WebODM workflows
6. **Board expansion** - Evaluate if batch/sandbox should get board tracking

---

## Support

- **Issues:** [GitHub Issues](https://github.com/protogen-org/ProtoGen-Claude-Workflow/issues)
- **Documentation:** See other files in [docs/](.)
- **Team Chat:** Ask in team Slack/Discord
