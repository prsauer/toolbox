$currentBranch = git rev-parse --abbrev-ref HEAD

function Test-UnstagedChanges {
    git diff --quiet 2>$null
    return $LASTEXITCODE -ne 0
}

function Test-StagedChanges {
    git diff --cached --quiet 2>$null
    return $LASTEXITCODE -ne 0
}

function Test-UntrackedFiles {
    $untracked = git ls-files --others --exclude-standard
    return [bool]$untracked
}

function Test-AnyChanges {
    return (Test-UnstagedChanges) -or (Test-StagedChanges) -or (Test-UntrackedFiles)
}

function Push-ToCurrentBranch {
    git add -A

    Write-Host "Generating commit message with Claude..."
    $commitDiff = @(git diff --cached --stat; git diff --cached) -join "`n"
    $commitMessage = $commitDiff | claude -p "Generate a concise git commit message (max 72 chars for first line) for these changes. Output ONLY the commit message, nothing else:"

    if ([string]::IsNullOrEmpty($commitMessage)) {
        Write-Host "Failed to generate commit message"
        exit 1
    }

    Write-Host "Committing with message: $commitMessage"
    git commit -m $commitMessage

    Write-Host "Pushing to origin..."
    git push
}

function Push-ToNewBranch {
    Write-Host "Generating branch name with Claude..."
    $diffOutput = @(git diff; git diff --cached; git status --short) -join "`n"
    $branchName = $diffOutput | claude -p "Generate a short, descriptive git branch name (no spaces, use hyphens, lowercase, max 50 chars) for these changes. Output ONLY the branch name, nothing else:"
    
    $branchName = $branchName -replace '\s', ''
    
    if ([string]::IsNullOrEmpty($branchName)) {
        Write-Host "Failed to generate branch name"
        exit 1
    }

    Write-Host "Creating and switching to branch: $branchName"
    git checkout -b $branchName

    git add -A

    Write-Host "Generating commit message with Claude..."
    $commitDiff = @(git diff --cached --stat; git diff --cached) -join "`n"
    $commitMessage = $commitDiff | claude -p "Generate a concise git commit message (max 72 chars for first line) for these changes. Output ONLY the commit message, nothing else:"

    if ([string]::IsNullOrEmpty($commitMessage)) {
        Write-Host "Failed to generate commit message"
        exit 1
    }

    Write-Host "Committing with message: $commitMessage"
    git commit -m $commitMessage

    Write-Host "Pushing to origin..."
    git push -u origin $branchName

    Write-Host "Generating PR description with Claude..."
    $prBody = $commitDiff | claude -p "Generate a brief PR description for these changes. Keep it concise and focus on what changed and why. Output ONLY the description, nothing else:"

    if ([string]::IsNullOrEmpty($prBody)) {
        $prBody = $commitMessage
    }

    Write-Host "Creating pull request..."
    gh pr create --title $commitMessage --body $prBody --base main
}

if ($currentBranch -eq "main") {
    if (Test-AnyChanges) {
        Write-Host "You are on the main branch." -ForegroundColor Yellow
        Write-Host "[1] Push directly to main"
        Write-Host "[2] Create a new branch"
        Write-Host "[q] Cancel"
        $choice = Read-Host "Choose an option"

        switch ($choice) {
            "1" {
                Push-ToCurrentBranch
            }
            "2" {
                Push-ToNewBranch
            }
            default {
                Write-Host "Cancelled."
                exit 0
            }
        }
    }
    else {
        Write-Host "No changes to commit on main branch."
    }
}
else {
    if (Test-AnyChanges) {
        Push-ToCurrentBranch
    }
    else {
        Write-Host "No changes to commit."
    }
}

Write-Host "Done!"
