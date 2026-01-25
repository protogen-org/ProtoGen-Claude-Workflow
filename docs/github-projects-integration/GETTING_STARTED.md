# Getting Started with GitHub Projects Integration

This guide walks through setting up Claude Code to work with ProtoGen's GitHub Projects board.

## Prerequisites

### 1. GitHub CLI Installation

Verify `gh` CLI is installed:

```powershell
gh --version
```

If not installed, download from: https://cli.github.com/

### 2. GitHub CLI Authentication

Check your authentication status:

```powershell
gh auth status
```

Expected output should show:
- Logged in as your GitHub username
- Token scopes including `repo`

### 3. Add Project Scope (Critical)

The GitHub Projects API requires the `project` scope. Add it:

```powershell
gh auth refresh -s project
```

This opens a browser for re-authentication. Approve the additional scope.

### 4. Verify Project Scope

Confirm the scope was added:

```powershell
gh auth status
```

Token scopes should now include: `project`, `repo`, `read:org`

## First-Time Setup

### Step 1: Pull Latest ProtoGen-Specs

```powershell
cd C:\path\to\ProtoGen-Specs
git checkout main
git pull origin main
```

### Step 2: Verify Configuration Files

Check that these files exist:
- `CLAUDE.md` - Claude Code instructions
- `.claude-project-config.yml` - Project IDs and field mappings
- `.claude/commands/` - Slash command definitions

### Step 3: Test the Integration

Open Claude Code and run:

```
/project-status
```

You should see items from the Grid Nav board grouped by status.

## Existing Configuration Protection

### Local CLAUDE.md Takes Precedence

If you have a local `CLAUDE.md` in your working repository (e.g., Dashboard, ProtoGen-tools-frontend), it takes precedence over the ProtoGen-Specs global one.

**To use GitHub Projects commands from any repo:**
1. The commands will still work - they reference ProtoGen-Specs config
2. Your local CLAUDE.md customizations are preserved
3. No files in your local repo are overwritten

### Backup Existing Customizations

Before using the integration, if you have existing customizations:

```powershell
# Check for existing .claude directory
ls .claude/

# If you have custom commands, back them up
cp -r .claude/ .claude-backup/
```

## Verification Checklist

Run through this checklist to verify setup:

- [ ] `gh --version` shows version 2.x or higher
- [ ] `gh auth status` shows logged in
- [ ] Token scopes include `project`
- [ ] `/project-status` displays board items
- [ ] `/project-create` prompts for issue details

## Team Workflow

### Starting New Work

1. **Use `/project-workflow`** to create issue + branch
   - Automatically names branch correctly
   - Sets up project board item
   - Checks out the new branch

2. **Develop as normal**
   - Make commits referencing issue number
   - Push changes to remote

3. **Create PR when ready**
   - Use `gh pr create --base dev`
   - Reference issue in PR body

4. **Track progress with `/project-update`**
   - Update status as work progresses
   - Add comments to issues

5. **Promote through stages with `/project-promote`**
   - Validates PR status before promotion
   - Updates project board automatically

### Checking CI/CD Status

Before requesting review or merging:

```
/project-cicd 123
```

Or check all open PRs:

```
/project-cicd --all
```

## Common First-Time Issues

### "Resource not accessible by integration"

**Cause**: Missing `project` scope

**Solution**:
```powershell
gh auth refresh -s project
```

### "Could not resolve to a ProjectV2"

**Cause**: Organization project access not granted

**Solution**:
1. Visit https://github.com/orgs/protogen-org/projects/8
2. Verify you can see the board
3. If not, request access from an org admin

### Commands Not Found

**Cause**: Claude Code not reading ProtoGen-Specs config

**Solution**:
1. Ensure you've pulled latest ProtoGen-Specs
2. Check that `.claude/commands/` directory exists
3. Restart Claude Code session

## Next Steps

- Review [COMMAND_REFERENCE.md](./COMMAND_REFERENCE.md) for detailed command usage
- See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for common issues
- Try creating a test issue with `/project-create`

## Getting Help

If you encounter issues:

1. Check the troubleshooting guide
2. Verify `gh auth status` shows correct scopes
3. Try the command with verbose output (if available)
4. Ask in the team channel with error details
