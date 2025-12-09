# Toolbox

A collection of CLI tools and scripts.

## Installation

The installer reads `manifest.json` to determine what to install. Before copying files, it verifies that all required dependencies are available by running commands defined in the `requirements` array—each must exit with code 0.

**macOS:**

```bash
./install_macos.sh
```

Requires: `git`, `jq`, `gh`

**Windows:**

```powershell
.\install_win.ps1
```

Requires: `git`, `gh`

## Scripts

### gup

**Location:** `git/gup.sh` (macOS) / `git/gup.ps1` (Windows)

A git workflow tool that uses Claude to automatically generate commit messages, branch names, and PR descriptions.

**Requirements:** `git`, `gh`, `claude` (Claude CLI)

**Usage:**

```bash
gup
```

**Behavior:**

- **On a feature branch:** Stages all changes, generates a commit message with Claude, commits, and pushes.
- **On main:** Prompts with options:
  - `[1]` Push directly to main
  - `[2]` Create a new branch (generates branch name, commits, pushes, and opens a PR)
  - `[q]` Cancel

**What it does:**

1. Detects uncommitted changes (staged, unstaged, untracked)
2. Uses Claude to analyze the diff and generate a concise commit message
3. When creating a new branch from main, also generates the branch name and PR description
4. Creates the PR via `gh pr create`
