# Claude Code Workflow Functions
# PowerShell equivalent of .claude-aliases.sh
# Source from PowerShell profile:
#   . "$env:USERPROFILE\Documents\ProtoGen-Claude-Workflow\scripts\powershell\claude-aliases.ps1"

# Common worktrees directory
$script:WORKTREES_DIR = "$env:USERPROFILE\Documents\worktrees"

function cc {
    param([Parameter(ValueFromRemainingArguments=$true)]$Args)

    Write-Host ""
    Write-Host "  PERMISSIONLESS MODE" -ForegroundColor Black -BackgroundColor Yellow
    Write-Host "  Claude will not ask for permission to execute commands or edit files." -ForegroundColor Yellow
    Write-Host ""

    $allowedTools = @("Bash", "Edit", "Write", "Read", "Glob", "Grep", "WebFetch", "WebSearch", "Task", "mcp__holoviz__*")
    claude --permission-mode dontAsk --allowedTools $allowedTools @Args
}

function ccw {
    param(
        [Parameter(Position=0)][string]$IssueNumber,
        [switch]$PlanOnly,
        [Parameter(ValueFromRemainingArguments=$true)]$RemainingArgs
    )

    if (-not $IssueNumber) {
        Write-Host "Error: Issue number required. Usage: ccw <issue#>" -ForegroundColor Red
        return
    }

    Write-Host "Setting up worktree for issue #$IssueNumber..." -ForegroundColor Cyan

    # Extract issue number if full URL provided
    if ($IssueNumber -match '/issues/(\d+)') {
        $IssueNumber = $Matches[1]
    }

    # Get repo root
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $repoRoot) {
        Write-Host "Error: Not in a git repository." -ForegroundColor Red
        return
    }
    $repoRoot = $repoRoot -replace '/', '\'

    # Get repo info
    $repoInfo = gh repo view --json nameWithOwner,name --template "{{.nameWithOwner}}|{{.name}}" 2>$null
    if (-not $repoInfo) {
        Write-Host "Error: Could not get repo info. Is gh CLI authenticated?" -ForegroundColor Red
        return
    }

    $repoFullName, $repoName = $repoInfo -split '\|'

    # Get issue title
    $issueTitle = gh issue view $IssueNumber --json title -q '.title' 2>$null
    if (-not $issueTitle) {
        Write-Host "Error: Could not fetch issue #$IssueNumber. Does it exist?" -ForegroundColor Red
        return
    }

    # Create branch name
    $branchSuffix = ($issueTitle.ToLower() -replace '[^a-z0-9 ]', '' -replace ' ', '-')
    if ($branchSuffix.Length -gt 30) {
        $branchSuffix = $branchSuffix.Substring(0, 30) -replace '-$', ''
    }
    $branchName = "feature/$repoName-$IssueNumber-$branchSuffix"

    # Create worktrees directory
    if (-not (Test-Path $script:WORKTREES_DIR)) {
        New-Item -ItemType Directory -Path $script:WORKTREES_DIR -Force | Out-Null
    }
    $fullWorktreePath = "$script:WORKTREES_DIR\$repoName-issue$IssueNumber"

    if (Test-Path $fullWorktreePath) {
        Write-Host "Worktree already exists at $fullWorktreePath" -ForegroundColor Yellow
        Write-Host "Resuming work on issue #$IssueNumber..." -ForegroundColor Cyan
    } else {
        # Determine base branch - default to main, but check if user is on different branch
        $currentBranch = git rev-parse --abbrev-ref HEAD
        $baseBranch = "main"

        if ($currentBranch -ne "main" -and $currentBranch -ne "master") {
            Write-Host ""
            Write-Host "You are currently on '$currentBranch' branch." -ForegroundColor Yellow
            $response = Read-Host "Create branch from '$currentBranch' instead of 'main'? [y/N]"
            if ($response -match '^[Yy]') {
                $baseBranch = $currentBranch
            }
        }

        # Fetch and pull latest from remote
        Write-Host "Fetching latest from origin/$baseBranch..." -ForegroundColor Cyan
        git fetch origin $baseBranch
        git checkout $baseBranch 2>$null
        git pull origin $baseBranch

        Write-Host "Creating worktree at $fullWorktreePath with branch $branchName from $baseBranch..." -ForegroundColor Cyan
        $result = git worktree add $fullWorktreePath -b $branchName $baseBranch 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Branch may exist, trying to use existing branch..." -ForegroundColor Yellow
            $result = git worktree add $fullWorktreePath $branchName 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Error: Failed to create worktree." -ForegroundColor Red
                return
            }
        }
    }

    # Copy environment files
    $envFiles = Get-ChildItem -Path $repoRoot -Filter ".env*" -File -ErrorAction SilentlyContinue
    if ($envFiles) {
        Write-Host "Copying environment files to worktree..." -ForegroundColor Yellow
        foreach ($envFile in $envFiles) {
            Copy-Item $envFile.FullName -Destination $fullWorktreePath
            Write-Host "  Copied: $($envFile.Name)" -ForegroundColor DarkGray
        }
    }

    $configFiles = @(".secrets", ".secrets.json", "secrets.json", ".dev.vars", "local.settings.json")
    foreach ($configFile in $configFiles) {
        $configPath = Join-Path $repoRoot $configFile
        if (Test-Path $configPath) {
            Copy-Item $configPath -Destination $fullWorktreePath
            Write-Host "  Copied: $configFile" -ForegroundColor DarkGray
        }
    }

    Set-Location $fullWorktreePath
    Write-Host "Changed to: $fullWorktreePath" -ForegroundColor Green

    $prompt = "/work $IssueNumber"
    Write-Host ""
    Write-Host "Issue: #$IssueNumber - $issueTitle" -ForegroundColor White
    Write-Host "Branch: $branchName" -ForegroundColor White
    Write-Host "Starting Claude Code with /work command..." -ForegroundColor Cyan
    Write-Host ""

    $allowedTools = @("Bash", "Edit", "Write", "Read", "Glob", "Grep", "WebFetch", "WebSearch", "Task", "mcp__holoviz__*")
    claude --permission-mode dontAsk --allowedTools $allowedTools -p $prompt @RemainingArgs
}

function ccw-clean {
    param(
        [Parameter(Position=0)][string]$IssueNumber,
        [switch]$All,
        [switch]$List,
        [string]$Repo
    )

    if ($List) {
        Write-Host "Worktrees in $script:WORKTREES_DIR`:" -ForegroundColor Cyan
        if (Test-Path $script:WORKTREES_DIR) {
            Get-ChildItem -Path $script:WORKTREES_DIR -Directory | ForEach-Object {
                Write-Host "  $($_.Name)" -ForegroundColor White
            }
        } else {
            Write-Host "  (none)" -ForegroundColor DarkGray
        }
        Write-Host ""
        Write-Host "Git worktree list:" -ForegroundColor Cyan
        git worktree list 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  (not in a git repo)" -ForegroundColor DarkGray
        }
        return
    }

    if ($All) {
        if (Test-Path $script:WORKTREES_DIR) {
            $parentRepos = @{}
            Get-ChildItem -Path $script:WORKTREES_DIR -Directory | ForEach-Object {
                $wtName = $_.Name
                $wtPath = $_.FullName
                if ($Repo -and -not ($wtName -match "^$Repo-")) {
                    return
                }
                Write-Host "Removing worktree: $wtName..." -ForegroundColor Yellow

                # Find parent repo from .git file
                $gitFile = Join-Path $wtPath ".git"
                if (Test-Path $gitFile) {
                    $gitContent = Get-Content $gitFile -Raw
                    if ($gitContent -match "gitdir:\s*(.+)") {
                        $gitDir = $Matches[1].Trim()
                        # Extract parent repo path (everything before .git/worktrees/)
                        if ($gitDir -match "^(.+)[/\\]\.git[/\\]worktrees[/\\]") {
                            $parentRepo = $Matches[1]
                            $parentRepos[$parentRepo] = $true
                            git -C $parentRepo worktree remove $wtPath --force 2>$null
                            if ($LASTEXITCODE -eq 0) {
                                return
                            }
                        }
                    }
                }
                # Fallback: delete directory directly
                Remove-Item -Path $wtPath -Recurse -Force -ErrorAction SilentlyContinue
            }
            # Prune all affected parent repos
            foreach ($repo in $parentRepos.Keys) {
                git -C $repo worktree prune 2>$null
            }
            Write-Host "Worktrees cleaned." -ForegroundColor Green
        } else {
            Write-Host "No worktrees directory found at $script:WORKTREES_DIR" -ForegroundColor Yellow
        }
    } elseif ($IssueNumber) {
        $repoName = gh repo view --json name -q '.name' 2>$null
        if (-not $repoName) {
            Write-Host "Error: Could not determine repo name. Are you in a git repo?" -ForegroundColor Red
            return
        }
        $worktreePath = "$script:WORKTREES_DIR\$repoName-issue$IssueNumber"
        if (Test-Path $worktreePath) {
            Write-Host "Removing worktree: $repoName-issue$IssueNumber..." -ForegroundColor Yellow
            git worktree remove $worktreePath --force
            git worktree prune
            Write-Host "Worktree removed." -ForegroundColor Green
        } else {
            Write-Host "No worktree found at $worktreePath" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Usage:" -ForegroundColor Yellow
        Write-Host "  ccw-clean <issue#>       - Remove worktree for issue (current repo)" -ForegroundColor White
        Write-Host "  ccw-clean -All           - Remove all worktrees" -ForegroundColor White
        Write-Host "  ccw-clean -All -Repo X   - Remove all worktrees for repo X" -ForegroundColor White
        Write-Host "  ccw-clean -List          - List all worktrees" -ForegroundColor White
    }
}

function pstop {
    # Check for python processes running Panel apps by command line pattern
    $pythonProcs = Get-CimInstance Win32_Process -Filter "Name='python.exe'" -ErrorAction SilentlyContinue |
        Where-Object { $_.CommandLine -match 'panel serve|sandbox_dash|circuit_viz|mpc_optimizer|batch_reopt|pv_viz' }

    $allProcs = @()
    if ($pythonProcs) {
        $pythonProcs | ForEach-Object {
            $proc = Get-Process -Id $_.ProcessId -ErrorAction SilentlyContinue
            if ($proc) { $allProcs += $proc }
        }
    }

    # Also check for processes listening on common Panel ports (5006-5011)
    $panelPorts = @(5006, 5008, 5009, 5010, 5011)
    foreach ($port in $panelPorts) {
        $netstat = netstat -ano | Select-String ":$port\s+.*LISTENING" | ForEach-Object {
            if ($_ -match '\s(\d+)\s*$') { $Matches[1] }
        }
        foreach ($procId in $netstat) {
            if ($procId -and $procId -ne "0") {
                $proc = Get-Process -Id $procId -ErrorAction SilentlyContinue
                if ($proc -and $proc.Name -eq "python" -and $allProcs.Id -notcontains $proc.Id) {
                    $allProcs += $proc
                }
            }
        }
    }

    if ($allProcs.Count -gt 0) {
        Write-Host "Stopping server processes..." -ForegroundColor Yellow
        $allProcs | ForEach-Object {
            Write-Host "  Killing PID $($_.Id) ($($_.Name))" -ForegroundColor DarkGray
            Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 1
        Write-Host "Server stopped" -ForegroundColor Green
    } else {
        Write-Host "No server found" -ForegroundColor Yellow
    }
}

function prv {
    param([Parameter(Position=0)][string]$PrNumber)

    if (-not $PrNumber) {
        Write-Host "Open PRs:" -ForegroundColor Yellow
        gh pr list
        Write-Host ""
        Write-Host "Usage: prv <pr-number>" -ForegroundColor Yellow
        return
    }

    $prInfo = gh pr view $PrNumber --json title,headRefName 2>$null | ConvertFrom-Json
    if (-not $prInfo) {
        Write-Host "Error: Could not fetch PR #$PrNumber" -ForegroundColor Red
        return
    }

    Write-Host "PR #$PrNumber`: $($prInfo.title)" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Files changed:" -ForegroundColor White
    gh pr diff $PrNumber --name-only
    Write-Host ""

    # Check if branch is in a worktree
    $worktreeList = git worktree list --porcelain 2>$null
    $worktreePath = $null
    $lines = $worktreeList -split "`n"
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "branch.*$($prInfo.headRefName)") {
            for ($j = $i; $j -ge 0; $j--) {
                if ($lines[$j] -match "^worktree (.+)") {
                    $worktreePath = $Matches[1]
                    break
                }
            }
            break
        }
    }

    if ($worktreePath -and (Test-Path $worktreePath)) {
        Write-Host "Branch is in worktree: $worktreePath" -ForegroundColor Yellow
        Write-Host "Changing to worktree..." -ForegroundColor Cyan
        Set-Location $worktreePath
    } else {
        Write-Host "Checking out PR #$PrNumber..." -ForegroundColor Cyan
        $result = gh pr checkout $PrNumber 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Error: Failed to checkout PR" -ForegroundColor Red
            return
        }
    }

    # Activate conda env if environment.yml exists
    if (Test-Path "environment.yml") {
        $envContent = Get-Content "environment.yml" -Raw
        if ($envContent -match "name:\s*(.+)") {
            $envName = $Matches[1].Trim()
            Write-Host "Activating conda env: $envName" -ForegroundColor Cyan
            conda activate $envName
        }
    }

    # Detect entry point from pyproject.toml (needed for install retry)
    $entryPoint = "<app_name>"
    if (Test-Path "pyproject.toml") {
        $pyproject = Get-Content "pyproject.toml" -Raw
        if ($pyproject -match '\[project\.scripts\][\s\S]*?(\w+)\s*=') {
            $entryPoint = $Matches[1]
        }
    }

    # Install package with retry logic
    Write-Host "Installing package (pip install -e .)..." -ForegroundColor Cyan
    $maxAttempts = 3
    $attempt = 1
    while ($attempt -le $maxAttempts) {
        $result = pip install -e . -q 2>&1
        if ($LASTEXITCODE -eq 0) {
            break
        } else {
            if ($attempt -lt $maxAttempts) {
                Write-Host "Install failed (file in use?). Killing $entryPoint processes..." -ForegroundColor Yellow
                # Kill the specific package exe that's likely holding the lock
                if ($entryPoint -ne "<app_name>") {
                    taskkill /F /IM "$entryPoint.exe" 2>$null
                }
                Start-Sleep -Seconds 1
                Write-Host "Retrying... (attempt $($attempt + 1)/$maxAttempts)" -ForegroundColor Yellow
            } else {
                Write-Host "Install failed after $maxAttempts attempts. Try: pstop; pip install -e ." -ForegroundColor Red
            }
        }
        $attempt++
    }

    Write-Host ""
    Write-Host "Ready to verify PR #$PrNumber" -ForegroundColor Green
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "  1. Run: " -ForegroundColor White -NoNewline
    Write-Host "$entryPoint" -ForegroundColor Cyan -NoNewline
    Write-Host " (Start-Job or & at end for background)" -ForegroundColor White
    Write-Host "  2. Test the changes in browser" -ForegroundColor White
    Write-Host "  3. When done: " -ForegroundColor White -NoNewline
    Write-Host "pstop; pr-done $PrNumber" -ForegroundColor Cyan
}

function pr-approve {
    param(
        [Parameter(Position=0)][string]$PrNumber,
        [Parameter(Position=1)][string]$Comment = "Verified and approved"
    )

    if (-not $PrNumber) {
        Write-Host "Usage: pr-approve <pr-number> [comment]" -ForegroundColor Red
        return
    }

    Write-Host "Approving PR #$PrNumber..." -ForegroundColor Cyan
    $result = gh pr review $PrNumber --approve -b $Comment 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to approve PR (you cannot approve your own PR)" -ForegroundColor Red
        return
    }
    Write-Host "PR #$PrNumber approved" -ForegroundColor Green
}

function pr-done {
    param(
        [Parameter(Position=0)][string]$PrNumber,
        [Parameter(Position=1)][string]$Comment = "Verified and approved"
    )

    if (-not $PrNumber) {
        Write-Host "Usage: pr-done <pr-number> [comment]" -ForegroundColor Red
        return
    }

    # Get branch name for worktree cleanup
    $branchName = gh pr view $PrNumber --json headRefName -q '.headRefName' 2>$null

    # Clean up worktree FIRST (before merge tries to delete branch)
    if ($branchName) {
        $worktreeList = git worktree list --porcelain 2>$null
        $worktreePath = $null
        $lines = $worktreeList -split "`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match "branch.*$branchName") {
                for ($j = $i; $j -ge 0; $j--) {
                    if ($lines[$j] -match "^worktree (.+)") {
                        $worktreePath = $Matches[1]
                        break
                    }
                }
                break
            }
        }

        if ($worktreePath -and (Test-Path $worktreePath)) {
            Write-Host "Cleaning up worktree: $worktreePath" -ForegroundColor Cyan
            $currentDir = Get-Location
            if ($currentDir.Path -like "$worktreePath*" -or $currentDir.Path -like "*\worktrees\*") {
                Set-Location "$env:USERPROFILE\Documents"
            }
            git worktree remove $worktreePath --force 2>$null
            git worktree prune
        }
    }

    # Try to approve (ignore error if it's your own PR)
    Write-Host "Approving PR #$PrNumber..." -ForegroundColor Cyan
    $result = gh pr review $PrNumber --approve -b $Comment 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Skipping approval (likely your own PR)" -ForegroundColor Yellow
    }

    # Merge the PR
    Write-Host "Merging PR #$PrNumber..." -ForegroundColor Cyan
    $result = gh pr merge $PrNumber --squash --delete-branch 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Merge failed" -ForegroundColor Red
        Write-Host $result
        return
    }

    # Return to main and pull
    Write-Host "Returning to main..." -ForegroundColor Cyan
    git checkout main
    git pull

    Write-Host "PR #$PrNumber merged and cleaned up" -ForegroundColor Green
}

function gpa {
    $repos = @(
        "circuit_viz",
        "mpc_optimizer",
        "batch_reopt",
        "dash",
        "tools_backend",
        "tools_frontend",
        "specs"
    )
    $needsAttention = @()

    foreach ($repo in $repos) {
        $repoPath = "$env:USERPROFILE\Documents\$repo"
        Write-Host "`n=== $repo ===" -ForegroundColor Cyan

        # Fetch first to get remote state
        git -C $repoPath fetch --quiet 2>$null

        $result = git -C $repoPath pull --ff-only 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host $result -ForegroundColor Green
        } else {
            $needsAttention += $repo
            Write-Host "  Needs attention" -ForegroundColor Yellow

            # Show uncommitted changes
            $status = git -C $repoPath status --short
            if ($status) {
                Write-Host "  Uncommitted changes:" -ForegroundColor White
                $status | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            }

            # Show local commits not on remote
            $localCommits = git -C $repoPath log origin/main..HEAD --oneline 2>$null
            if ($localCommits) {
                Write-Host "  Local commits not pushed:" -ForegroundColor White
                $localCommits | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
            }
        }
    }

    # Summary with commands
    if ($needsAttention.Count -gt 0) {
        Write-Host "`n========================================" -ForegroundColor Yellow
        Write-Host "Repos needing attention: $($needsAttention -join ', ')" -ForegroundColor Yellow
        Write-Host "`nCommands to resolve:" -ForegroundColor White
        foreach ($repo in $needsAttention) {
            Write-Host "`n  $repo`:" -ForegroundColor Cyan
            Write-Host "    Merge:  cd ~/Documents/$repo && git pull" -ForegroundColor DarkGray
            Write-Host "    Rebase: cd ~/Documents/$repo && git pull --rebase" -ForegroundColor DarkGray
            Write-Host "    Reset:  cd ~/Documents/$repo && git reset --hard origin/main" -ForegroundColor DarkGray
        }
    }
}

function dashcheck {
    Write-Host ""
    Write-Host "Dashboard Health Check" -ForegroundColor Cyan
    Write-Host "Run '/dashcheck' in Claude Code to smoke test all dashboards" -ForegroundColor White
    Write-Host ""
    Write-Host "Dashboards:" -ForegroundColor White
    Write-Host "  dash        (dev)  - port 5006" -ForegroundColor DarkGray
    Write-Host "  batch_reopt (main) - port 5009" -ForegroundColor DarkGray
    Write-Host "  sandbox_dash(main) - port 5010" -ForegroundColor DarkGray
    Write-Host "  pv_viz      (main) - port 5011" -ForegroundColor DarkGray
    Write-Host "  circuit_viz (main) - port 5008" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Quick start:" -ForegroundColor White
    Write-Host "  cc '/dashcheck'" -ForegroundColor Cyan
}

Write-Host "Claude workflow: cc, ccw, ccw-clean, pstop, prv, pr-approve, pr-done, gpa, dashcheck" -ForegroundColor DarkGray
