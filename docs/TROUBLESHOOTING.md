# Troubleshooting Guide

Common issues and solutions for the ProtoGen Claude Workflow.

## Table of Contents

- [Setup Issues](#setup-issues)
- [Slash Command Issues](#slash-command-issues)
- [GitHub Authentication Issues](#github-authentication-issues)
- [GitHub Projects Issues](#github-projects-issues)
- [Git and Branch Issues](#git-and-branch-issues)
- [CI/CD Issues](#cicd-issues)
- [Dashboard Development Issues](#dashboard-development-issues)
- [Getting More Help](#getting-more-help)

---

## Setup Issues

### Slash Commands Not Working

**Symptom:** `/issues` or `/work` not recognized in Claude Code

**Solutions:**

1. **Verify symlink exists:**
   ```bash
   ls -la ~/.claude/commands
   # Should show symlink pointing to workflow repo
   ```

2. **Check Claude Code version:**
   ```bash
   claude --version
   # Should be 2.0.0 or higher
   ```

3. **Recreate symlink if broken:**

   **Windows (Run as Administrator):**
   ```powershell
   Remove-Item "$env:USERPROFILE\.claude\commands" -Force -ErrorAction SilentlyContinue
   New-Item -ItemType SymbolicLink `
       -Path "$env:USERPROFILE\.claude\commands" `
       -Target "C:\path\to\ProtoGen-Claude-Workflow\.claude\commands"
   ```

   **Linux/macOS:**
   ```bash
   rm ~/.claude/commands
   ln -s ~/path/to/ProtoGen-Claude-Workflow/.claude/commands ~/.claude/commands
   ```

4. **Restart Claude Code session**

---

### Workflow Functions Not Loading

**Symptom:** `cc` command not found

**Windows:**
```powershell
# Check if profile exists and loads
Test-Path $PROFILE
# Manually source the workflow
. "$env:USERPROFILE\Documents\ProtoGen-Claude-Workflow\scripts\powershell\claude-aliases.ps1"
```

**Linux/macOS:**
```bash
# Check if sourced in profile
grep -i "claude-aliases" ~/.bashrc
# Manually source
source "$HOME/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"
```

---

### Symlink Creation Failed (Windows)

**Symptom:** "You do not have sufficient privilege"

**Solution:** Run PowerShell as Administrator
- Right-click PowerShell icon → "Run as Administrator"
- Then create symlink again

---

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

---

### Conda Not Activating

**Symptom:** Environment doesn't auto-activate when entering directory

**Check:**
1. Conda is installed: `conda --version`
2. `environment.yml` exists in directory
3. Profile was reloaded after adding conda activation code

---

## Slash Command Issues

### Commands Not Recognized

**Symptom:** Claude doesn't recognize `/project-status` or other commands

**Causes:**
1. Symlink not set up correctly
2. `.claude/commands/` directory missing or empty

**Solutions:**
1. Verify command files exist:
   ```bash
   ls ~/.claude/commands/
   # Should show: issues.md, work.md, project-*.md, etc.
   ```

2. Pull latest workflow repo:
   ```bash
   cd ~/path/to/ProtoGen-Claude-Workflow
   git pull origin main
   ```

3. Restart Claude Code session

---

### Command Hangs or Times Out

**Symptom:** Command starts but never completes

**Causes:**
1. Large number of items to process
2. API rate limiting
3. Network issues

**Solutions:**
1. Use filters to reduce item count:
   ```
   /project-status --project GRID
   ```

2. Check rate limit status:
   ```bash
   gh api rate_limit
   ```

3. Wait and retry if rate limited

---

### Incorrect Repository Detection

**Symptom:** Wrong repository selected for issue creation

**Solution:**
1. Specify repository explicitly: `/issues repo: owner/repo <description>`
2. Verify you're in the correct directory before running commands

---

## GitHub Authentication Issues

### "Resource not accessible by integration"

**Symptom:** GraphQL queries fail with 403 error

**Cause:** Missing `project` scope on your GitHub token.

**Solution:**
```bash
gh auth refresh -s project
```

Then verify:
```bash
gh auth status
# Token scopes should include: project, repo, read:org
```

---

### "Bad credentials"

**Symptom:** All `gh` commands fail

**Cause:** Token expired or revoked.

**Solution:**
```bash
gh auth login
```
Follow the prompts to re-authenticate.

---

### "Must have push access to repository"

**Symptom:** Cannot create issues or update items

**Cause:** Insufficient repository permissions.

**Solution:**
1. Verify you have write access to the repository
2. Contact an org admin if needed
3. Check you're targeting the correct repository

---

## GitHub Projects Issues

### "Could not resolve to a ProjectV2"

**Symptom:** Cannot access project board, project queries return null

**Causes:**
1. Project ID is incorrect
2. You don't have access to the project

**Solutions:**

1. Verify project access:
   ```bash
   gh api graphql -f query='
   query {
     organization(login: "protogen-org") {
       projectsV2(first: 10) {
         nodes { id title number }
       }
     }
   }'
   ```

2. If Grid Nav (#8) isn't listed, request access from an org admin.

3. Visit https://github.com/orgs/protogen-org/projects/8 to verify you can see the board.

---

### "Field not found" or "Invalid option ID"

**Symptom:** Cannot update specific fields, GraphQL mutation fails

**Cause:** Field or option IDs in config don't match current board structure.

**Solution:**
1. Query current field IDs:
   ```bash
   gh api graphql -f query='
   query {
     node(id: "PVT_kwDOC5eI7s4BK2oC") {
       ... on ProjectV2 {
         fields(first: 20) {
           nodes {
             ... on ProjectV2SingleSelectField {
               id name options { id name }
             }
           }
         }
       }
     }
   }'
   ```

2. Compare with `.claude-project-config.yml`
3. Update config if IDs have changed
4. Submit PR with updates

---

### Item Not Appearing on Board

**Symptom:** Issue created but not visible on project board

**Causes:**
1. Board view is filtered
2. Item was added to wrong project

**Solutions:**
1. Check board filters - clear all filters
2. Search for item by issue number
3. Manually add via GitHub UI if needed

---

## Git and Branch Issues

### "Cannot create branch"

**Symptom:** Branch creation fails

**Causes:**
1. No push access to repository
2. Branch already exists
3. Not in a git repository

**Solutions:**
1. Verify you're in the correct repository
2. Check if branch exists:
   ```bash
   git branch -a | grep "branch-name"
   ```
3. Delete existing branch if appropriate

---

### "Failed to set upstream"

**Symptom:** Branch created locally but push fails

**Solution:**
```bash
git push -u origin branch-name
```

---

### Branch Naming Conflicts

**Symptom:** Generated branch name already exists

**Solution:**
The workflow checks for existing branches. If collision occurs:
1. Use a different description
2. Delete old unused branches
3. Manually create with higher sequence number

---

### Worktree Issues

**Symptom:** `ccw` fails or worktree is corrupted

**Solutions:**

1. List existing worktrees:
   ```bash
   ccw-clean -List
   ```

2. Remove problematic worktree:
   ```bash
   ccw-clean <issue#>
   ```

3. Force cleanup if needed:
   ```bash
   git worktree prune
   ```

---

## CI/CD Issues

### "No workflow runs found"

**Symptom:** `/project-cicd` shows no results

**Causes:**
1. No workflows triggered yet
2. Branch not pushed
3. Workflow file issues

**Solutions:**
1. Verify branch is pushed:
   ```bash
   git push origin branch-name
   ```

2. Check workflow file exists in repository
3. View GitHub Actions tab in browser

---

### "CI checks not passing"

**Symptom:** Cannot promote past review, validation fails

**Solution:**
1. View detailed failure:
   ```bash
   gh run view RUN_ID --log
   ```

2. Fix the failing tests/checks
3. Push fixes and wait for CI to complete
4. Use `/project-promote --force` if check is false positive (not recommended)

---

## Dashboard Development Issues

### `pip install` fails with "WinError 32"

**Cause:** A server is still running and holding a file lock.

**Solution:**
```powershell
pstop
pip install -e .
```

---

### Port Already in Use

**Symptom:** "Address already in use" when running dashboard

**Solution:**
```powershell
# Stop all Panel servers
pstop

# Or find and kill specific process
# Windows:
netstat -ano | findstr :5006
taskkill /PID <pid> /F

# Linux/macOS:
lsof -i :5006
kill -9 <pid>
```

---

### Dashboard Not Showing Changes

**Symptom:** Code changes not reflected in running dashboard

**Solutions:**
1. Ensure you're using `--dev` flag for hot reload:
   ```bash
   make serve
   # or
   panel serve app.py --dev --show
   ```

2. Re-run editable install:
   ```bash
   make install
   # or
   pip install -e .
   ```

3. Clear browser cache

---

## Getting More Help

### Debug Information to Collect

When reporting issues, include:

1. **Command used**: Exact command with options
2. **Error message**: Full error text
3. **Auth status**: `gh auth status` output
4. **Repository**: Which repo you're working in
5. **Branch**: Current branch name
6. **Claude Code version**: `claude --version`

### Manual Workarounds

If commands fail, you can always:

1. **Create issues manually**: GitHub web UI
2. **Update board manually**: Drag items in board view
3. **Create branches manually**:
   ```bash
   git checkout -b feature/PROJECT-YYYYMMDD-##-description origin/dev
   ```

### Reporting Issues

For persistent issues:
1. Check this troubleshooting guide
2. Try manual workaround
3. Create issue in [ProtoGen-Claude-Workflow](https://github.com/protogen-org/ProtoGen-Claude-Workflow/issues)
4. Include debug information listed above
