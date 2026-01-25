# Troubleshooting Guide

Common issues and solutions for the GitHub Projects integration.

## Authentication Issues

### "Resource not accessible by integration"

**Symptoms:**
- GraphQL queries fail with 403 error
- Commands return "Resource not accessible"

**Cause:** Missing `project` scope on your GitHub token.

**Solution:**
```powershell
gh auth refresh -s project
```

Then verify:
```powershell
gh auth status
# Should show 'project' in token scopes
```

### "Bad credentials"

**Symptoms:**
- All `gh` commands fail
- Authentication errors

**Cause:** Token expired or revoked.

**Solution:**
```powershell
gh auth login
```

Follow the prompts to re-authenticate.

### "Must have push access to repository"

**Symptoms:**
- Cannot create issues or update items
- Write operations fail

**Cause:** Insufficient repository permissions.

**Solution:**
1. Verify you have write access to the repository
2. Contact an org admin if needed
3. Check you're targeting the correct repository

---

## Project Board Issues

### "Could not resolve to a ProjectV2"

**Symptoms:**
- Cannot access project board
- Project queries return null

**Causes:**
1. Project ID is incorrect
2. You don't have access to the project

**Solutions:**

Verify project access:
```powershell
# List projects you can access
gh api graphql -f query='
query {
  organization(login: "protogen-org") {
    projectsV2(first: 10) {
      nodes { id title number }
    }
  }
}'
```

If Grid Nav (#8) isn't listed, request access from an org admin.

### "Field not found" or "Invalid option ID"

**Symptoms:**
- Cannot update specific fields
- GraphQL mutation fails

**Cause:** Field or option IDs in config don't match current board structure.

**Solution:**
1. Query current field IDs:
```powershell
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

### Item Not Appearing on Board

**Symptoms:**
- Issue created but not on project board
- Board update succeeded but item not visible

**Causes:**
1. Item was added but view is filtered
2. GraphQL mutation succeeded but item ID is wrong

**Solutions:**
1. Check board filters - clear all filters
2. Search for item by issue number
3. Manually add via GitHub UI if needed

---

## Command Issues

### Commands Not Recognized

**Symptoms:**
- `/project-status` not found
- Claude doesn't recognize commands

**Causes:**
1. Not in ProtoGen-Specs context
2. `.claude/commands/` directory missing

**Solutions:**
1. Pull latest ProtoGen-Specs:
```powershell
cd C:\path\to\ProtoGen-Specs
git pull origin main
```

2. Verify command files exist:
```powershell
ls .claude/commands/
```

3. Restart Claude Code session

### Command Hangs or Times Out

**Symptoms:**
- Command starts but never completes
- Long wait with no output

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
```powershell
gh api rate_limit
```

3. Wait and retry if rate limited

### Incorrect Repository Detection

**Symptoms:**
- Wrong repository selected for issue creation
- Branch created in wrong repo

**Cause:** Repository mapping doesn't match project prefix.

**Solution:**
1. Specify repository explicitly when prompted
2. For GRID prefix, specify frontend vs backend
3. Check repository mapping in config

---

## Branch and Git Issues

### "Cannot create branch"

**Symptoms:**
- Branch creation fails
- Permission denied errors

**Causes:**
1. No push access to repository
2. Branch already exists
3. Not in a git repository

**Solutions:**
1. Verify you're in the correct repository
2. Check if branch exists:
```powershell
git branch -a | grep "branch-name"
```
3. Delete existing branch if appropriate

### "Failed to set upstream"

**Symptoms:**
- Branch created locally but push fails
- Upstream tracking not set

**Solution:**
```powershell
git push -u origin branch-name
```

### Branch Naming Conflicts

**Symptoms:**
- Generated branch name already exists
- Sequence number collision

**Solution:**
The workflow checks for existing branches. If collision occurs:
1. Use a different description
2. Delete old unused branches
3. Manually create with higher sequence number

---

## CI/CD Issues

### "No workflow runs found"

**Symptoms:**
- `/project-cicd` shows no results
- CI status unavailable

**Causes:**
1. No workflows triggered yet
2. Branch not pushed
3. Workflow file issues

**Solutions:**
1. Verify branch is pushed:
```powershell
git push origin branch-name
```

2. Check workflow file exists in repository
3. View GitHub Actions tab in browser

### "CI checks not passing"

**Symptoms:**
- Cannot promote past review
- Validation fails

**Solution:**
1. View detailed failure:
```powershell
gh run view RUN_ID --log
```

2. Fix the failing tests/checks
3. Push fixes and wait for CI to complete
4. Use `/project-promote --force` if check is false positive (not recommended)

---

## Configuration Issues

### Config File Not Found

**Symptoms:**
- Commands fail to read configuration
- "Config file not found" errors

**Solution:**
1. Verify file exists:
```powershell
ls .claude-project-config.yml
```

2. Pull latest ProtoGen-Specs if missing
3. Check file permissions

### Config Parsing Errors

**Symptoms:**
- YAML syntax errors
- Invalid configuration

**Solution:**
1. Validate YAML syntax:
```powershell
# Use online YAML validator or:
python -c "import yaml; yaml.safe_load(open('.claude-project-config.yml'))"
```

2. Check for:
   - Proper indentation (2 spaces)
   - No tabs
   - Quoted strings with special characters

---

## Getting More Help

### Debug Information to Collect

When reporting issues, include:

1. **Command used**: Exact command with options
2. **Error message**: Full error text
3. **Auth status**: `gh auth status` output
4. **Repository**: Which repo you're working in
5. **Branch**: Current branch name

### Manual Workarounds

If commands fail, you can always:

1. **Create issues manually**: GitHub web UI
2. **Update board manually**: Drag items in board view
3. **Create branches manually**:
```powershell
git checkout -b feature/PROJECT-YYYYMMDD-##-description origin/dev
```

### Reporting Issues

For persistent issues:
1. Check this troubleshooting guide
2. Try manual workaround
3. Report to team with debug information
4. Consider submitting PR to fix if you identify the issue
