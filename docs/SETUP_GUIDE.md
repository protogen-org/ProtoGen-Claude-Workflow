# ProtoGen Claude Code Workflow - Setup Guide

Complete setup instructions for Windows and Linux/macOS.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
  - [Windows Setup](#windows-setup)
  - [Linux/macOS Setup](#linuxmacos-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)
- [Next Steps](#next-steps)

## Prerequisites

Before starting, ensure you have:

### Required
- ✅ **Claude Code** - Install globally: `npm install -g @anthropic-ai/claude-code`
- ✅ **GitHub CLI** - [Install from cli.github.com](https://cli.github.com/)
- ✅ **Git** - Version control
- ✅ **Node.js** - Required for Claude Code (v18 or higher)

### Recommended
- ✅ **Conda/Anaconda** - For Python environment management
- ✅ **VS Code** - Code editor with integrated terminal
- ✅ **PowerShell 7+** (Windows) or **Bash** (Linux/macOS)

### Verify Prerequisites

```bash
# Check installations
claude --version
gh --version
git --version
node --version
conda --version  # If using Anaconda
```

### GitHub CLI Authentication

If not already authenticated:
```bash
gh auth login
# Follow prompts to authenticate with GitHub
```

**Important:** Ensure your GitHub token has these scopes:
- `repo` - Full control of private repositories
- `read:org` - Read org and team membership
- `project` - Full control of projects (required for GitHub Projects integration)

To add the `project` scope if missing:
```bash
gh auth refresh -s project
```

---

## Installation Steps

### Windows Setup

#### 1. Clone the Repository

```powershell
# Navigate to your Documents folder (or preferred location)
cd $env:USERPROFILE\Documents\specs

# Clone the repository
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git

# Verify it cloned successfully
cd ProtoGen-Claude-Workflow
ls
```

#### 2. Set Up Slash Commands (Symlink)

**Run PowerShell as Administrator** for this step.

```powershell
# Create .claude directory if it doesn't exist
New-Item -ItemType Directory -Path "$env:USERPROFILE\.claude" -Force -ErrorAction SilentlyContinue

# Remove existing commands symlink if present (backup first if custom)
if (Test-Path "$env:USERPROFILE\.claude\commands") {
    # Optional: backup existing commands
    # Move-Item "$env:USERPROFILE\.claude\commands" "$env:USERPROFILE\.claude\commands.backup"
    Remove-Item "$env:USERPROFILE\.claude\commands" -Force
}

# Create symlink to repo commands
New-Item -ItemType SymbolicLink `
    -Path "$env:USERPROFILE\.claude\commands" `
    -Target "$env:USERPROFILE\Documents\specs\ProtoGen-Claude-Workflow\.claude\commands"
```

**Verify symlink:**
```powershell
ls "$env:USERPROFILE\.claude\commands"
# Should show: issues.md, work.md, startup.md, closedown.md, project-*.md, etc.
```

#### 3. Set Up PowerShell Profile

Find your PowerShell profile location:
```powershell
echo $PROFILE
# Typical: C:\Users\<username>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

Create or edit your profile:
```powershell
# Open in notepad
notepad $PROFILE

# If file doesn't exist, create parent directory first
New-Item -ItemType Directory -Path (Split-Path $PROFILE -Parent) -Force -ErrorAction SilentlyContinue
```

**Add this content** (or copy from `templates/powershell-profile.ps1.template`):

```powershell
# Git Integration - Show current branch in prompt
Import-Module posh-git -ErrorAction SilentlyContinue
$GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true

# ProtoGen Claude Code Workflow Functions
$claudeWorkflowPath = "$env:USERPROFILE\Documents\specs\ProtoGen-Claude-Workflow\scripts\powershell\claude-aliases.ps1"
if (Test-Path $claudeWorkflowPath) {
    . $claudeWorkflowPath
    Write-Host "ProtoGen Claude workflow loaded" -ForegroundColor DarkGray
} else {
    Write-Host "Warning: Claude workflow not found at $claudeWorkflowPath" -ForegroundColor Yellow
}

# Conda Environment Auto-Activation
function Set-LocationWithCondaActivate {
    param([string]$Path)
    if ($Path) {
        Microsoft.PowerShell.Management\Set-Location $Path
    }
    if (Test-Path "environment.yml") {
        $envContent = Get-Content "environment.yml" -Raw
        if ($envContent -match "name:\s*(.+)") {
            $envName = $Matches[1].Trim()
            if ($env:CONDA_DEFAULT_ENV -ne $envName) {
                conda activate $envName 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Activated conda env: $envName" -ForegroundColor DarkGray
                }
            }
        }
    }
}
Set-Alias -Name cd -Value Set-LocationWithCondaActivate -Option AllScope -Force
Set-LocationWithCondaActivate
```

**Save and close** the file.

#### 4. Install posh-git (Optional but Recommended)

If you don't have posh-git installed:
```powershell
Install-Module posh-git -Scope CurrentUser -Force
```

#### 5. Set Up MCP Servers (Optional but Recommended)

Use the template as a starting point:
```powershell
# Copy template to your global .claude.json
# WARNING: This will overwrite existing .claude.json - backup first!
Copy-Item templates\.claude.json.template "$env:USERPROFILE\.claude.json"

# Or manually add MCP servers from template to existing .claude.json
```

**Team-standard MCP servers:**
- `holoviz` - Panel/hvPlot documentation
- `context7` - General library documentation
- `playwright` - Browser automation
- `mui-mcp` - Material UI documentation

See [MCP_SERVERS.md](MCP_SERVERS.md) for detailed setup.

#### 6. Restart PowerShell

Close and reopen PowerShell (or VS Code terminal) to load the profile.

---

### Linux/macOS Setup

#### 1. Clone the Repository

```bash
# Navigate to your home directory
cd ~

# Clone the repository
git clone https://github.com/protogen-org/ProtoGen-Claude-Workflow.git

# Verify it cloned successfully
cd ProtoGen-Claude-Workflow
ls -la
```

#### 2. Set Up Slash Commands (Symlink)

```bash
# Create .claude directory if it doesn't exist
mkdir -p ~/.claude

# Remove existing commands symlink if present (backup first if custom)
if [ -L ~/.claude/commands ] || [ -d ~/.claude/commands ]; then
    # Optional: backup existing commands
    # mv ~/.claude/commands ~/.claude/commands.backup
    rm -rf ~/.claude/commands
fi

# Create symlink to repo commands
ln -s "$(pwd)/.claude/commands" "$HOME/.claude/commands"
```

**Verify symlink:**
```bash
ls -la ~/.claude/commands
# Should show: issues.md, work.md, startup.md, closedown.md, project-*.md, etc.
```

#### 3. Set Up Bash Profile

Find your shell profile:
```bash
# For Bash (most common)
echo $SHELL
# If output is /bin/bash, edit ~/.bashrc or ~/.bash_profile

# For Zsh (macOS default)
# Edit ~/.zshrc
```

**Edit your profile:**
```bash
# For Bash
nano ~/.bashrc
# or
nano ~/.bash_profile

# For Zsh (macOS)
nano ~/.zshrc
```

**Add this content** (or copy from `templates/bash-profile.sh.template`):

```bash
# ProtoGen Claude Code Workflow Functions
CLAUDE_WORKFLOW_PATH="$HOME/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"
if [ -f "$CLAUDE_WORKFLOW_PATH" ]; then
    source "$CLAUDE_WORKFLOW_PATH"
    echo "ProtoGen Claude workflow loaded" >&2
else
    echo "Warning: Claude workflow not found at $CLAUDE_WORKFLOW_PATH" >&2
fi

# Conda Environment Auto-Activation
cd_with_conda_activate() {
    builtin cd "$@"
    if [ -f "environment.yml" ]; then
        ENV_NAME=$(grep "^name:" environment.yml | sed 's/name:[[:space:]]*//')
        if [ -n "$ENV_NAME" ] && [ "$CONDA_DEFAULT_ENV" != "$ENV_NAME" ]; then
            conda activate "$ENV_NAME" 2>/dev/null
            if [ $? -eq 0 ]; then
                echo "Activated conda env: $ENV_NAME" >&2
            fi
        fi
    fi
}
alias cd='cd_with_conda_activate'
```

**Save and close** (Ctrl+X, then Y, then Enter in nano).

#### 4. Set Up MCP Servers (Optional but Recommended)

**Note:** MCP server commands may differ on Linux. For example:
```bash
# holoviz - works the same (uvx is cross-platform)
claude mcp add holoviz -- uvx holoviz-mcp

# context7 - HTTP-based, works the same
claude mcp add context7 --transport http --url https://mcp.context7.com/mcp

# playwright - use npx directly (not cmd /c)
claude mcp add playwright -- npx @playwright/mcp@latest
```

See [MCP_SERVERS.md](MCP_SERVERS.md) for detailed setup.

#### 5. Reload Shell

```bash
# Reload your profile
source ~/.bashrc
# or
source ~/.bash_profile
# or for Zsh
source ~/.zshrc
```

---

## Verification

Test that everything is working:

### 1. Verify Workflow Functions Loaded

**Windows:**
```powershell
# Open new PowerShell and check for functions
Get-Command cc, ccw, prv, pr-done, pstop -ErrorAction SilentlyContinue
# Should show: cc, ccw, prv, pr-done, pstop functions
```

**Linux/macOS:**
```bash
# Check if functions exist
type cc ccw prv pr-done pstop
# Should show: cc is a function, ccw is a function, etc.
```

### 2. Verify Slash Commands

```bash
# List slash commands
ls ~/.claude/commands
# Should show 11 .md files

# Test in Claude Code
cc
> /issues
# Claude should recognize the command and show the issues skill prompt
```

### 3. Verify Git Workflow

```bash
# Navigate to a git repo
cd ~/Documents/specs  # or any ProtoGen repo

# Test basic function
cc
# Should launch Claude Code in permissionless mode
```

### 4. Test MCP Servers (if configured)

```bash
# List MCP servers
claude mcp list
# Should show configured servers (holoviz, context7, etc.)
```

---

## Troubleshooting

### Slash Commands Not Working

**Issue:** `/issues` or `/work` not recognized

**Solutions:**
1. Verify symlink exists:
   ```bash
   ls -la ~/.claude/commands
   ```

2. Check Claude Code version:
   ```bash
   claude --version
   # Should be 2.0.0 or higher
   ```

3. Restart Claude Code session

### Workflow Functions Not Loading

**Issue:** `cc` command not found

**Windows:**
```powershell
# Check if profile is loading
$PROFILE
Test-Path $PROFILE

# Manually source the workflow
. "$env:USERPROFILE\Documents\specs\ProtoGen-Claude-Workflow\scripts\powershell\claude-aliases.ps1"
```

**Linux/macOS:**
```bash
# Check if profile is loading
echo $SHELL
cat ~/.bashrc  # or ~/.bash_profile or ~/.zshrc

# Manually source the workflow
source "$HOME/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"
```

### Symlink Creation Failed (Windows)

**Issue:** "You do not have sufficient privilege"

**Solution:** Run PowerShell as Administrator
```powershell
# Right-click PowerShell icon → "Run as Administrator"
# Then create symlink again
```

### MCP Server Not Connecting

```bash
# Check server status
claude mcp list

# Remove and re-add server
claude mcp remove holoviz
claude mcp add holoviz -- uvx holoviz-mcp

# Check for errors
claude mcp logs holoviz
```

### Conda Not Activating

**Issue:** Environment doesn't auto-activate when entering directory

**Check:**
1. Conda is installed: `conda --version`
2. `environment.yml` exists in directory
3. Profile was reloaded after adding conda activation code

---

## Next Steps

Once setup is complete:

1. **Read the Workflow Guide** - [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md)
   - Complete development workflow walkthrough
   - Example workflows for common tasks

2. **Read Command Reference** - [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md)
   - All slash commands with examples
   - All workflow functions with usage

3. **Try the Workflow** - Create your first issue
   ```bash
   cd ~/Documents/<your-repo>
   cc
   > /issues Add a new feature to the dashboard
   ```

4. **Review GitHub Projects Commands**
   - See [Command Reference](COMMAND_REFERENCE.md) for `/project-*` commands
   - Project board management via `/project-status`, `/project-create`, `/project-workflow`
   - CI/CD monitoring via `/project-cicd`

5. **Customize Your Setup**
   - Add personal aliases to profile
   - Configure additional MCP servers
   - Adjust workflow functions to your preferences

---

## Getting Help

- **Documentation:** Check [docs/](.) directory
- **Troubleshooting:** [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Command Reference:** [COMMAND_REFERENCE.md](COMMAND_REFERENCE.md)
- **Team Questions:** Ask in team chat or create a GitHub issue

**Welcome to the ProtoGen Claude Code workflow!**
