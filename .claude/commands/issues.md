---
description: Research a repository and create a well-structured GitHub issue following best practices
---

# GitHub Issue Creator

You are an expert at creating high-quality GitHub issues that follow best practices and project-specific conventions.

## Input
- Issue Description: $ARGUMENTS (paste the output from Claude Code prompt generator here)
- Repository: Defaults to current repo. To target a different repo, include "repo: owner/repo" at the start of your description.

## Workflow Tiers

This command adapts its behavior based on the repository's workflow tier:

| Tier | Description | Behavior |
|------|-------------|----------|
| **Tier 1** | Production repos (ProtoGen-tools-Dashboard, tools-frontend, etc.) | Full research + project board integration |
| **Tier 2** | Team dev tools (der-Simulator, pgnode1-server) | Full research, labels only, no board |
| **Tier 3** | Personal/sandbox repos | Streamlined research, basic issue |
| **External** | Non-protogen-org repos | Full research, follows target repo conventions |

## Process

### 0. Pre-flight Checks
- Verify `gh` CLI is authenticated by running `gh auth status`
- If not authenticated, instruct the user to run `gh auth login` first
- Parse the input:
  - If $ARGUMENTS starts with "repo:" or "repo :", extract the repo (e.g., "repo: holoviz/panel") and use the remainder as the issue description
  - Otherwise, use the entire $ARGUMENTS as the issue description
- Determine the target repository:
  - If a repo was specified in the input, use that
  - Otherwise, detect the current repo using `gh repo view --json nameWithOwner -q .nameWithOwner`
- Validate the repository exists and is accessible

### 0a. Determine Workflow Tier

**For non-protogen-org repos:** Mark as "External" and skip tier selection.

**For protogen-org repos:** **STOP and ask the user to select the workflow tier. DO NOT auto-select or infer the tier - you MUST prompt and wait for the user's response.**

Present these options and wait for selection:

> "This is a protogen-org repository. Which workflow tier should I use?"
> 1. **Tier 1 (Production)** - Full workflow with GitHub Projects board
> 2. **Tier 2 (Team Dev)** - Team collaboration, no project board
> 3. **Tier 3 (Personal/Sandbox)** - Minimal workflow

**Examples of each tier:**
- Tier 1: ProtoGen-tools-Dashboard, tools-frontend, tools-backend, map, REopt-Engine, Specs
- Tier 2: der-Simulator, pgnode1-server, shared dev tools
- Tier 3: Personal sandboxes, experiments, scratch repos

**Wait for the user to respond before continuing.**

Use the selected tier to determine behavior in subsequent steps:
- **Tier 1**: Execute all steps including Step 7 (Project Board Integration)
- **Tier 2**: Execute Steps 1-6, skip Step 7, add team labels
- **Tier 3**: Streamlined execution - skip duplicate deep-search, minimal research, basic issue structure
- **External**: Execute Steps 1-6, follow target repo conventions

### 1. Check for Duplicates
**Tier 3**: Do a quick title search only. **All other tiers**: Full duplicate search.

- Search existing open AND closed issues for similar problems using `gh issue list` and `gh search issues`
- If potential duplicates are found, present them to the user and ask whether to:
  - Continue with a new issue (referencing the related ones)
  - Comment on an existing issue instead
  - Abort

### 2. Research the Repository
**Tier 3**: Skip this step - use basic issue format. **All other tiers**: Full research.

- Visit the provided repository and examine its existing structure, issues, and documentation
- Look for CONTRIBUTING.md, issue templates, or any files containing guidelines for creating issues
- Note the project's coding style, naming conventions, and conventions for submitting issues
- Review existing issues to understand the project's preferred format and tone
- Identify any issue templates the project uses (bug report, feature request, etc.)

### 3. Research Best Practices
**Tier 3**: Skip this step. **All other tiers**: Full research.

- Consider current best practices for writing GitHub issues, focusing on:
  - Clarity: Make the issue easy to understand
  - Completeness: Include all necessary context and information
  - Actionability: Ensure the issue can be acted upon
- Draw inspiration from well-written issues in popular open-source projects
- **Use the context7 MCP server** to look up current documentation for any libraries or frameworks relevant to the issue
- **Use the holoviz MCP server** when the issue involves Panel, hvPlot, HoloViews, or other HoloViz ecosystem tools to ensure accurate terminology and current API references
- **Use web search** to find related discussions on Stack Overflow, forums, or other projects that may provide context or solutions

### 4. Present a Plan
Based on your research, outline a plan for creating the GitHub issue:
- Proposed structure of the issue (title, description, sections)
- Any labels or milestones you plan to use
- How you'll incorporate project-specific conventions
- Related issues/PRs to reference
- For multi-repo issues: identify all affected repositories and propose whether to create linked issues or a single issue with cross-references

Present this plan in `<plan>` tags and wait for approval.

### 5. Create the GitHub Issue
Once the plan is approved, draft the issue content:

**Title:**
- Write a clear, concise title that summarizes the issue
- Follow any project naming conventions (e.g., `[BUG]`, `feat:`, etc.)

**Description:**
- Context and motivation
- Expected behavior or desired feature
- Current behavior (for bugs)
- Steps to reproduce (for bugs)
- Proposed solution or implementation approach
- Any relevant screenshots, code snippets, or examples

**For Bugs - Include Environment Info:**
- Library/package version(s)
- Python version (if applicable)
- Operating system
- Browser (if applicable)
- Minimal reproducible example

**For Features - Include Acceptance Criteria:**
- Clear, testable criteria for when the feature is complete
- Edge cases to consider

**References:**
- Link to related issues, PRs, or discussions
- Link to relevant documentation or external resources

**Code References (at bottom of issue):**
- Search the codebase for relevant files related to the issue
- Include specific file paths with line numbers (e.g., `src/components/DatePicker.tsx:142`)
- For GitHub repos, convert local paths to GitHub permalink URLs (e.g., `https://github.com/owner/repo/blob/main/src/file.ts#L142-L150`)
- Include examples of:
  - Where the bug occurs or where the feature should be implemented
  - Related/similar implementations to reference
  - Test files that may need updating
- Format as a "Code References" section at the bottom of the issue

**Formatting:**
- Use appropriate Markdown formatting to enhance readability
- Consider the perspective of both project maintainers and potential contributors

**Security Check:**
- Review the draft for any sensitive information (API keys, passwords, internal URLs, PII)
- Warn the user if any potentially sensitive data is detected

### 6. Multi-Repository Issues
If the issue spans multiple repositories:
- Identify the primary repository for the main issue
- List secondary repositories that need linked issues
- Propose a cross-referencing strategy
- After creating the primary issue, offer to create linked issues in other repos

### 7. Project Board Integration (Tier 1 Only)

**Skip this step unless Tier 1 was selected in Step 0a.**

For Tier 1 (Production) repositories, after the issue is created, add it to the project board.

#### 7a. Collect Project Metadata

Ask the user for:
- **Type**: feature | bug | hotfix | task
- **Project**: GRID | DASH | MAP | REOPT | DB | MGNAV | SPEC
- **Priority**: P0 (Critical) | P1 (High) | P2 (Medium) | P3 (Low). Default: P2

#### 7b. Add to Project Board

```bash
# Get issue node ID
ISSUE_ID=$(gh issue view ISSUE_NUMBER --repo protogen-org/REPO --json id -q .id)

# Add to project
gh api graphql -f query='
mutation {
  addProjectV2ItemById(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    contentId: "'$ISSUE_ID'"
  }) {
    item { id }
  }
}'
```

#### 7c. Set Project Fields

Use the field IDs from `.claude-project-config.yml` (in workflow repo or current directory) to set fields:

```bash
# Get the project item ID from Step 7b response, then:
gh api graphql -f query='
mutation {
  updateProjectV2ItemFieldValue(input: {
    projectId: "PVT_kwDOC5eI7s4BK2oC"
    itemId: "ITEM_ID"
    fieldId: "FIELD_ID"
    value: { singleSelectOptionId: "OPTION_ID" }
  }) {
    projectV2Item { id }
  }
}'
```

Set these fields:
- **Work Type**: Based on type parameter
- **Project**: Based on project parameter
- **Priority**: Based on priority parameter (default P2)
- **Status**: Set to "Backlog" (or "In Progress" for hotfixes)

#### 7d. Hotfix Special Handling

For hotfixes:
- Set Priority to P1 (High) automatically unless P0 specified
- Set Status to "In Progress" (skip Backlog)
- Remind user: hotfix branches come from `main`, merge to main/staging/dev

### 8. Final Output
Present the complete GitHub issue content in `<github_issue>` tags.

The issue should end with a Code References section like this:

```markdown
## Code References

- Implementation location: [`src/widgets/datepicker.py:87-142`](https://github.com/owner/repo/blob/main/src/widgets/datepicker.py#L87-L142)
- Similar widget for reference: [`src/widgets/slider.py:45-98`](https://github.com/owner/repo/blob/main/src/widgets/slider.py#L45-L98)
- Related tests: [`tests/test_datepicker.py`](https://github.com/owner/repo/blob/main/tests/test_datepicker.py)
```

After the tags, provide the exact `gh` CLI command(s) to create the issue:

```bash
gh issue create --repo <owner/repo> \
  --title "<title>" \
  --body "<body>" \
  --label "<bug|enhancement|...>" \
  --assignee @me
```

Include any other relevant flags (--milestone, --project).

**For Tier 1 repos**, after issue creation, display project board status:

```
Issue created successfully!

  Issue: #123
  Title: [Feature] Add user dashboard widget
  Repo:  protogen-org/ProtoGen-tools-frontend
  URL:   https://github.com/protogen-org/ProtoGen-tools-frontend/issues/123

Project board updated:
  Status:   Backlog
  Type:     Feature
  Project:  GRID
  Priority: P2 - Medium

Next steps:
  1. Create branch: feature/GRID-20260123-01-user-dashboard-widget
  2. Or use /project-workflow to automate branch creation
```

**Optional:** Ask the user if they want to:
1. Create the issue immediately
2. Create as a draft (if supported by the repo)
3. Copy the content to clipboard for manual creation
4. Make further edits

## Usage Examples

```
# External repo - full research, follows repo conventions
/issues repo: holoviz/panel Create a DatePicker widget that supports a "disabled" parameter...

# Tier 1 (Production) - will prompt to confirm tier, then full workflow + board
/issues repo: protogen-org/ProtoGen-tools-Dashboard Add a loading spinner to the dashboard

# Tier 2 (Team Dev) - will prompt to confirm tier, full research, no board
/issues repo: protogen-org/der-Simulator Add support for new inverter model

# Tier 3 (Personal) - will prompt to confirm tier, streamlined workflow
/issues repo: protogen-org/sandbox_dash Fix the voltage display scaling issue

# Using current repo (detects repo, prompts for tier if protogen-org)
/issues Create a DatePicker widget that supports a "disabled" parameter.

# Typical workflow:
# 1. Craft your feature/bug description
# 2. Run: /issues <description>
# 3. If protogen-org repo, select the appropriate tier when prompted
```

## Related Commands

- `/project-create` - Quick Tier 1 issue creation for PMs (skips research, goes straight to board)
- `/project-workflow` - Start working on an issue (creates branch, updates status)

## Tier Reference

See [Migration Guide](../docs/MIGRATION_GUIDE.md) for complete tier documentation.
