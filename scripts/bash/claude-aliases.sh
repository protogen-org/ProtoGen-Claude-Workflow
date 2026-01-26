#!/usr/bin/env bash
# Claude Code Workflow Functions
# Bash equivalent of claude-aliases.ps1
# Source from bash profile:
#   source "$HOME/ProtoGen-Claude-Workflow/scripts/bash/claude-aliases.sh"

# Common worktrees directory
WORKTREES_DIR="$HOME/Documents/worktrees"

# ANSI color codes
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_CYAN='\033[0;36m'
COLOR_WHITE='\033[0;37m'
COLOR_GRAY='\033[0;90m'
COLOR_BG_YELLOW='\033[43m'
COLOR_BLACK='\033[0;30m'

# Helper function for colored output
color_echo() {
    local color="$1"
    shift
    echo -e "${color}$*${COLOR_RESET}"
}

# cc - Launch Claude Code in permissionless mode
cc() {
    echo ""
    echo -e "${COLOR_BLACK}${COLOR_BG_YELLOW}  PERMISSIONLESS MODE${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}  Claude will not ask for permission to execute commands or edit files.${COLOR_RESET}"
    echo ""

    local allowed_tools="Bash,Edit,Write,Read,Glob,Grep,WebFetch,WebSearch,Task,mcp__holoviz__*"
    claude --permission-mode dontAsk --allowedTools "$allowed_tools" "$@"
}

# ccw - Create worktree for issue and launch Claude
ccw() {
    local issue_number="$1"
    shift  # Remove first argument, rest go to claude

    if [ -z "$issue_number" ]; then
        color_echo "$COLOR_RED" "Error: Issue number required. Usage: ccw <issue#>"
        return 1
    fi

    color_echo "$COLOR_CYAN" "Setting up worktree for issue #$issue_number..."

    # Extract issue number if full URL provided
    if [[ "$issue_number" =~ /issues/([0-9]+) ]]; then
        issue_number="${BASH_REMATCH[1]}"
    fi

    # Get repo root
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$repo_root" ]; then
        color_echo "$COLOR_RED" "Error: Not in a git repository."
        return 1
    fi

    # Get repo info
    local repo_info
    repo_info=$(gh repo view --json nameWithOwner,name --template "{{.nameWithOwner}}|{{.name}}" 2>/dev/null)
    if [ -z "$repo_info" ]; then
        color_echo "$COLOR_RED" "Error: Could not get repo info. Is gh CLI authenticated?"
        return 1
    fi

    local repo_full_name="${repo_info%|*}"
    local repo_name="${repo_info#*|}"

    # Get issue title
    local issue_title
    issue_title=$(gh issue view "$issue_number" --json title -q '.title' 2>/dev/null)
    if [ -z "$issue_title" ]; then
        color_echo "$COLOR_RED" "Error: Could not fetch issue #$issue_number. Does it exist?"
        return 1
    fi

    # Create branch name
    local branch_suffix
    branch_suffix=$(echo "$issue_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 ]//g' | tr ' ' '-')
    if [ ${#branch_suffix} -gt 30 ]; then
        branch_suffix="${branch_suffix:0:30}"
        branch_suffix="${branch_suffix%-}"  # Remove trailing dash
    fi
    local branch_name="feature/$repo_name-$issue_number-$branch_suffix"

    # Create worktrees directory
    mkdir -p "$WORKTREES_DIR"
    local full_worktree_path="$WORKTREES_DIR/$repo_name-issue$issue_number"

    if [ -d "$full_worktree_path" ]; then
        color_echo "$COLOR_YELLOW" "Worktree already exists at $full_worktree_path"
        color_echo "$COLOR_CYAN" "Resuming work on issue #$issue_number..."
    else
        # Determine base branch - default to main, but check if user is on different branch
        local current_branch
        current_branch=$(git rev-parse --abbrev-ref HEAD)
        local base_branch="main"

        if [ "$current_branch" != "main" ] && [ "$current_branch" != "master" ]; then
            echo ""
            color_echo "$COLOR_YELLOW" "You are currently on '$current_branch' branch."
            read -p "Create branch from '$current_branch' instead of 'main'? [y/N] " -n 1 -r response
            echo
            if [[ $response =~ ^[Yy]$ ]]; then
                base_branch="$current_branch"
            fi
        fi

        # Fetch and pull latest from remote
        color_echo "$COLOR_CYAN" "Fetching latest from origin/$base_branch..."
        git fetch origin "$base_branch"
        git checkout "$base_branch" 2>/dev/null
        git pull origin "$base_branch"

        color_echo "$COLOR_CYAN" "Creating worktree at $full_worktree_path with branch $branch_name from $base_branch..."
        if ! git worktree add "$full_worktree_path" -b "$branch_name" "$base_branch" 2>&1; then
            color_echo "$COLOR_YELLOW" "Branch may exist, trying to use existing branch..."
            if ! git worktree add "$full_worktree_path" "$branch_name" 2>&1; then
                color_echo "$COLOR_RED" "Error: Failed to create worktree."
                return 1
            fi
        fi
    fi

    # Copy environment files
    local env_files
    env_files=$(find "$repo_root" -maxdepth 1 -type f -name ".env*" 2>/dev/null)
    if [ -n "$env_files" ]; then
        color_echo "$COLOR_YELLOW" "Copying environment files to worktree..."
        while IFS= read -r env_file; do
            cp "$env_file" "$full_worktree_path/"
            color_echo "$COLOR_GRAY" "  Copied: $(basename "$env_file")"
        done <<< "$env_files"
    fi

    # Copy config files
    local config_files=(".secrets" ".secrets.json" "secrets.json" ".dev.vars" "local.settings.json")
    for config_file in "${config_files[@]}"; do
        if [ -f "$repo_root/$config_file" ]; then
            cp "$repo_root/$config_file" "$full_worktree_path/"
            color_echo "$COLOR_GRAY" "  Copied: $config_file"
        fi
    done

    cd "$full_worktree_path" || return 1
    color_echo "$COLOR_GREEN" "Changed to: $full_worktree_path"

    local prompt="/work $issue_number"
    echo ""
    color_echo "$COLOR_WHITE" "Issue: #$issue_number - $issue_title"
    color_echo "$COLOR_WHITE" "Branch: $branch_name"
    color_echo "$COLOR_CYAN" "Starting Claude Code with /work command..."
    echo ""

    local allowed_tools="Bash,Edit,Write,Read,Glob,Grep,WebFetch,WebSearch,Task,mcp__holoviz__*"
    claude --permission-mode dontAsk --allowedTools "$allowed_tools" -p "$prompt" "$@"
}

# ccw-clean - Clean up worktrees
ccw-clean() {
    local issue_number=""
    local list_mode=false
    local all_mode=false
    local repo_filter=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -l|--list)
                list_mode=true
                shift
                ;;
            -a|--all)
                all_mode=true
                shift
                ;;
            -r|--repo)
                repo_filter="$2"
                shift 2
                ;;
            *)
                issue_number="$1"
                shift
                ;;
        esac
    done

    if $list_mode; then
        color_echo "$COLOR_CYAN" "Worktrees in $WORKTREES_DIR:"
        if [ -d "$WORKTREES_DIR" ]; then
            for wt in "$WORKTREES_DIR"/*; do
                if [ -d "$wt" ]; then
                    color_echo "$COLOR_WHITE" "  $(basename "$wt")"
                fi
            done
        else
            color_echo "$COLOR_GRAY" "  (none)"
        fi
        echo ""
        color_echo "$COLOR_CYAN" "Git worktree list:"
        if ! git worktree list 2>/dev/null; then
            color_echo "$COLOR_GRAY" "  (not in a git repo)"
        fi
        return 0
    fi

    if $all_mode; then
        if [ -d "$WORKTREES_DIR" ]; then
            for wt in "$WORKTREES_DIR"/*; do
                if [ -d "$wt" ]; then
                    local wt_name
                    wt_name=$(basename "$wt")
                    if [ -n "$repo_filter" ] && [[ ! "$wt_name" =~ ^$repo_filter- ]]; then
                        continue
                    fi
                    color_echo "$COLOR_YELLOW" "Removing worktree: $wt_name..."
                    git worktree remove "$wt" --force 2>/dev/null
                fi
            done
            git worktree prune 2>/dev/null
            color_echo "$COLOR_GREEN" "Worktrees cleaned."
        else
            color_echo "$COLOR_YELLOW" "No worktrees directory found at $WORKTREES_DIR"
        fi
    elif [ -n "$issue_number" ]; then
        local repo_name
        repo_name=$(gh repo view --json name -q '.name' 2>/dev/null)
        if [ -z "$repo_name" ]; then
            color_echo "$COLOR_RED" "Error: Could not determine repo name. Are you in a git repo?"
            return 1
        fi
        local worktree_path="$WORKTREES_DIR/$repo_name-issue$issue_number"
        if [ -d "$worktree_path" ]; then
            color_echo "$COLOR_YELLOW" "Removing worktree: $repo_name-issue$issue_number..."
            git worktree remove "$worktree_path" --force
            git worktree prune
            color_echo "$COLOR_GREEN" "Worktree removed."
        else
            color_echo "$COLOR_YELLOW" "No worktree found at $worktree_path"
        fi
    else
        color_echo "$COLOR_YELLOW" "Usage:"
        color_echo "$COLOR_WHITE" "  ccw-clean <issue#>           - Remove worktree for issue (current repo)"
        color_echo "$COLOR_WHITE" "  ccw-clean --all              - Remove all worktrees"
        color_echo "$COLOR_WHITE" "  ccw-clean --all --repo X     - Remove all worktrees for repo X"
        color_echo "$COLOR_WHITE" "  ccw-clean --list             - List all worktrees"
    fi
}

# pstop - Stop running Panel/dashboard servers
pstop() {
    local panel_ports=(5006 5007 5008 5009 5010 5011)
    local pids_to_kill=()

    # Find python processes running Panel apps
    while IFS= read -r line; do
        if [[ "$line" =~ panel\ serve|sandbox_dash|circuit_viz|mpc_optimizer|batch_reopt|pv_viz ]]; then
            local pid
            pid=$(echo "$line" | awk '{print $2}')
            if [ -n "$pid" ]; then
                pids_to_kill+=("$pid")
            fi
        fi
    done < <(ps aux | grep python 2>/dev/null)

    # Also check for processes listening on Panel ports
    for port in "${panel_ports[@]}"; do
        # Use lsof on Linux/macOS to find processes on ports
        if command -v lsof &> /dev/null; then
            local pid
            pid=$(lsof -ti ":$port" 2>/dev/null)
            if [ -n "$pid" ]; then
                # Check if already in list
                if [[ ! " ${pids_to_kill[*]} " =~ " ${pid} " ]]; then
                    pids_to_kill+=("$pid")
                fi
            fi
        fi
    done

    if [ ${#pids_to_kill[@]} -gt 0 ]; then
        color_echo "$COLOR_YELLOW" "Stopping server processes..."
        for pid in "${pids_to_kill[@]}"; do
            local proc_name
            proc_name=$(ps -p "$pid" -o comm= 2>/dev/null || echo "unknown")
            color_echo "$COLOR_GRAY" "  Killing PID $pid ($proc_name)"
            kill -9 "$pid" 2>/dev/null
        done
        sleep 1
        color_echo "$COLOR_GREEN" "Server stopped"
    else
        color_echo "$COLOR_YELLOW" "No server found"
    fi
}

# prv - Checkout and verify PR
prv() {
    local pr_number="$1"

    if [ -z "$pr_number" ]; then
        color_echo "$COLOR_YELLOW" "Open PRs:"
        gh pr list
        echo ""
        color_echo "$COLOR_YELLOW" "Usage: prv <pr-number>"
        return 0
    fi

    local pr_info
    pr_info=$(gh pr view "$pr_number" --json title,headRefName 2>/dev/null)
    if [ -z "$pr_info" ]; then
        color_echo "$COLOR_RED" "Error: Could not fetch PR #$pr_number"
        return 1
    fi

    local pr_title
    pr_title=$(echo "$pr_info" | jq -r '.title')
    local head_ref
    head_ref=$(echo "$pr_info" | jq -r '.headRefName')

    color_echo "$COLOR_CYAN" "PR #$pr_number: $pr_title"
    echo ""

    color_echo "$COLOR_WHITE" "Files changed:"
    gh pr diff "$pr_number" --name-only
    echo ""

    # Check if branch is in a worktree
    local worktree_path=""
    while IFS= read -r line; do
        if [[ "$line" =~ ^worktree ]]; then
            worktree_path="${line#worktree }"
        elif [[ "$line" =~ branch.*$head_ref ]]; then
            if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
                color_echo "$COLOR_YELLOW" "Branch is in worktree: $worktree_path"
                color_echo "$COLOR_CYAN" "Changing to worktree..."
                cd "$worktree_path" || return 1
                break
            fi
        fi
    done < <(git worktree list --porcelain 2>/dev/null)

    # If not in worktree, checkout PR
    if [ ! -d "$worktree_path" ] || [ "$(pwd)" != "$worktree_path" ]; then
        color_echo "$COLOR_CYAN" "Checking out PR #$pr_number..."
        if ! gh pr checkout "$pr_number" 2>&1; then
            color_echo "$COLOR_RED" "Error: Failed to checkout PR"
            return 1
        fi
    fi

    # Activate conda env if environment.yml exists
    if [ -f "environment.yml" ]; then
        local env_name
        env_name=$(grep "^name:" environment.yml | sed 's/name:[[:space:]]*//')
        if [ -n "$env_name" ]; then
            color_echo "$COLOR_CYAN" "Activating conda env: $env_name"
            conda activate "$env_name" 2>/dev/null
        fi
    fi

    # Detect entry point from pyproject.toml
    local entry_point="<app_name>"
    if [ -f "pyproject.toml" ]; then
        entry_point=$(grep -A 10 '\[project\.scripts\]' pyproject.toml | grep -m 1 '=' | sed 's/\s*=.*//' | tr -d ' "')
    fi

    # Install package with retry logic
    color_echo "$COLOR_CYAN" "Installing package (pip install -e .)..."
    local max_attempts=3
    local attempt=1
    while [ $attempt -le $max_attempts ]; do
        if pip install -e . -q 2>&1; then
            break
        else
            if [ $attempt -lt $max_attempts ]; then
                color_echo "$COLOR_YELLOW" "Install failed (file in use?). Killing $entry_point processes..."
                if [ "$entry_point" != "<app_name>" ]; then
                    pkill -f "$entry_point" 2>/dev/null
                fi
                sleep 1
                color_echo "$COLOR_YELLOW" "Retrying... (attempt $((attempt + 1))/$max_attempts)"
            else
                color_echo "$COLOR_RED" "Install failed after $max_attempts attempts. Try: pstop; pip install -e ."
            fi
        fi
        attempt=$((attempt + 1))
    done

    echo ""
    color_echo "$COLOR_GREEN" "Ready to verify PR #$pr_number"
    color_echo "$COLOR_WHITE" "Next steps:"
    echo -e "  1. Run: ${COLOR_CYAN}$entry_point${COLOR_WHITE} (add & at end for background)"
    echo -e "  2. Test the changes in browser"
    echo -e "  3. When done: ${COLOR_CYAN}pstop; pr-done $pr_number${COLOR_RESET}"
}

# pr-approve - Approve a PR
pr-approve() {
    local pr_number="$1"
    local comment="${2:-Verified and approved}"

    if [ -z "$pr_number" ]; then
        color_echo "$COLOR_RED" "Usage: pr-approve <pr-number> [comment]"
        return 1
    fi

    color_echo "$COLOR_CYAN" "Approving PR #$pr_number..."
    if ! gh pr review "$pr_number" --approve -b "$comment" 2>&1; then
        color_echo "$COLOR_RED" "Failed to approve PR (you cannot approve your own PR)"
        return 1
    fi
    color_echo "$COLOR_GREEN" "PR #$pr_number approved"
}

# pr-done - Merge PR and clean up
pr-done() {
    local pr_number="$1"
    local comment="${2:-Verified and approved}"

    if [ -z "$pr_number" ]; then
        color_echo "$COLOR_RED" "Usage: pr-done <pr-number> [comment]"
        return 1
    fi

    # Get branch name for worktree cleanup
    local branch_name
    branch_name=$(gh pr view "$pr_number" --json headRefName -q '.headRefName' 2>/dev/null)

    # Clean up worktree FIRST (before merge tries to delete branch)
    if [ -n "$branch_name" ]; then
        local worktree_path=""
        while IFS= read -r line; do
            if [[ "$line" =~ ^worktree ]]; then
                worktree_path="${line#worktree }"
            elif [[ "$line" =~ branch.*$branch_name ]]; then
                if [ -n "$worktree_path" ] && [ -d "$worktree_path" ]; then
                    color_echo "$COLOR_CYAN" "Cleaning up worktree: $worktree_path"
                    local current_dir
                    current_dir=$(pwd)
                    if [[ "$current_dir" == "$worktree_path"* ]] || [[ "$current_dir" == */worktrees/* ]]; then
                        cd "$HOME/Documents" || cd "$HOME"
                    fi
                    git worktree remove "$worktree_path" --force 2>/dev/null
                    git worktree prune
                    break
                fi
            fi
        done < <(git worktree list --porcelain 2>/dev/null)
    fi

    # Try to approve (ignore error if it's your own PR)
    color_echo "$COLOR_CYAN" "Approving PR #$pr_number..."
    if ! gh pr review "$pr_number" --approve -b "$comment" 2>&1; then
        color_echo "$COLOR_YELLOW" "Skipping approval (likely your own PR)"
    fi

    # Merge the PR
    color_echo "$COLOR_CYAN" "Merging PR #$pr_number..."
    if ! gh pr merge "$pr_number" --squash --delete-branch 2>&1; then
        color_echo "$COLOR_RED" "Merge failed"
        return 1
    fi

    # Return to main and pull
    color_echo "$COLOR_CYAN" "Returning to main..."
    git checkout main
    git pull

    color_echo "$COLOR_GREEN" "PR #$pr_number merged and cleaned up"
}

# gpa - Git pull all repos
gpa() {
    local repos=(
        "circuit_viz"
        "mpc_optimizer"
        "batch_reopt"
        "dash"
        "tools_backend"
        "tools_frontend"
        "specs"
    )
    local needs_attention=()

    for repo in "${repos[@]}"; do
        local repo_path="$HOME/Documents/$repo"
        echo ""
        color_echo "$COLOR_CYAN" "=== $repo ==="

        # Fetch first to get remote state
        git -C "$repo_path" fetch --quiet 2>/dev/null

        if git -C "$repo_path" pull --ff-only 2>&1; then
            color_echo "$COLOR_GREEN" "Updated successfully"
        else
            needs_attention+=("$repo")
            color_echo "$COLOR_YELLOW" "  Needs attention"

            # Show uncommitted changes
            local status
            status=$(git -C "$repo_path" status --short 2>/dev/null)
            if [ -n "$status" ]; then
                color_echo "$COLOR_WHITE" "  Uncommitted changes:"
                echo "$status" | while IFS= read -r line; do
                    color_echo "$COLOR_GRAY" "    $line"
                done
            fi

            # Show local commits not on remote
            local local_commits
            local_commits=$(git -C "$repo_path" log origin/main..HEAD --oneline 2>/dev/null)
            if [ -n "$local_commits" ]; then
                color_echo "$COLOR_WHITE" "  Local commits not pushed:"
                echo "$local_commits" | while IFS= read -r line; do
                    color_echo "$COLOR_GRAY" "    $line"
                done
            fi
        fi
    done

    # Summary with commands
    if [ ${#needs_attention[@]} -gt 0 ]; then
        echo ""
        color_echo "$COLOR_YELLOW" "========================================"
        color_echo "$COLOR_YELLOW" "Repos needing attention: ${needs_attention[*]}"
        color_echo "$COLOR_WHITE" "\nCommands to resolve:"
        for repo in "${needs_attention[@]}"; do
            echo ""
            color_echo "$COLOR_CYAN" "  $repo:"
            color_echo "$COLOR_GRAY" "    Merge:  cd ~/Documents/$repo && git pull"
            color_echo "$COLOR_GRAY" "    Rebase: cd ~/Documents/$repo && git pull --rebase"
            color_echo "$COLOR_GRAY" "    Reset:  cd ~/Documents/$repo && git reset --hard origin/main"
        done
    fi
}

# dashcheck - Dashboard health check info
dashcheck() {
    echo ""
    color_echo "$COLOR_CYAN" "Dashboard Health Check"
    color_echo "$COLOR_WHITE" "Run '/dashcheck' in Claude Code to smoke test all dashboards"
    echo ""
    color_echo "$COLOR_WHITE" "Dashboards:"
    color_echo "$COLOR_GRAY" "  dash        (dev)  - port 5006"
    color_echo "$COLOR_GRAY" "  batch_reopt (main) - port 5009"
    color_echo "$COLOR_GRAY" "  sandbox_dash(main) - port 5010"
    color_echo "$COLOR_GRAY" "  pv_viz      (main) - port 5011"
    color_echo "$COLOR_GRAY" "  circuit_viz (main) - port 5008"
    echo ""
    color_echo "$COLOR_WHITE" "Quick start:"
    color_echo "$COLOR_CYAN" "  cc '/dashcheck'"
}

# Load message
color_echo "$COLOR_GRAY" "Claude workflow: cc, ccw, ccw-clean, pstop, prv, pr-approve, pr-done, gpa, dashcheck"
