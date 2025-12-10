#!/bin/bash

current_branch=$(git rev-parse --abbrev-ref HEAD)

# Colors
CYAN='\033[36m'
WHITE='\033[37m'
RESET='\033[0m'

print_claude_result() {
    local label="$1"
    local content="$2"
    echo -e "${CYAN}<<CLAUDE:${label}>>${RESET}"
    echo -e "${WHITE}${content}${RESET}"
    echo -e "${CYAN}<</CLAUDE>>${RESET}"
}

test_unstaged_changes() {
    ! git diff --quiet 2>/dev/null
}

test_staged_changes() {
    ! git diff --cached --quiet 2>/dev/null
}

test_untracked_files() {
    [[ -n $(git ls-files --others --exclude-standard) ]]
}

test_any_changes() {
    test_unstaged_changes || test_staged_changes || test_untracked_files
}

push_to_current_branch() {
    git add -A

    echo "Generating commit message with Claude..."
    commit_diff=$(git diff --cached --stat; git diff --cached)
    commit_message=$(echo "$commit_diff" | claude -p "Generate a concise git commit message (max 72 chars for first line) for these changes. Output ONLY the commit message, nothing else:")

    if [[ -z "$commit_message" ]]; then
        echo "Failed to generate commit message"
        exit 1
    fi

    print_claude_result "commit_message" "$commit_message"
    git commit -m "$commit_message"

    echo "Pushing to origin..."
    git push
}

push_to_new_branch() {
    echo "Generating branch name with Claude..."
    diff_output=$(git diff; git diff --cached; git status --short)
    branch_name=$(echo "$diff_output" | claude -p "Generate a short, descriptive git branch name (no spaces, use hyphens, lowercase, max 50 chars) for these changes. Output ONLY the branch name, nothing else:")

    branch_name=$(echo "$branch_name" | tr -d '[:space:]')

    if [[ -z "$branch_name" ]]; then
        echo "Failed to generate branch name"
        exit 1
    fi

    print_claude_result "branch_name" "$branch_name"
    git checkout -b "$branch_name"

    git add -A

    echo "Generating commit message with Claude..."
    commit_diff=$(git diff --cached --stat; git diff --cached)
    commit_message=$(echo "$commit_diff" | claude -p "Generate a concise git commit message (max 72 chars for first line) for these changes. Output ONLY the commit message, nothing else:")

    if [[ -z "$commit_message" ]]; then
        echo "Failed to generate commit message"
        exit 1
    fi

    print_claude_result "commit_message" "$commit_message"
    git commit -m "$commit_message"

    echo "Pushing to origin..."
    git push -u origin "$branch_name"

    echo "Generating PR description with Claude..."
    pr_body=$(echo "$commit_diff" | claude -p "Generate a brief PR description for these changes. Keep it concise and focus on what changed and why. Output ONLY the description, nothing else:")

    if [[ -z "$pr_body" ]]; then
        pr_body="$commit_message"
    fi

    print_claude_result "pr_description" "$pr_body"
    gh pr create --title "$commit_message" --body "$pr_body" --base main
}

if [[ "$current_branch" == "main" ]]; then
    if test_any_changes; then
        echo -e "\033[33mYou are on the main branch.\033[0m"
        echo "[1] Push directly to main"
        echo "[2] Create a new branch"
        echo "[q] Cancel"
        read -p "Choose an option: " choice

        case "$choice" in
            1)
                push_to_current_branch
                ;;
            2)
                push_to_new_branch
                ;;
            *)
                echo "Cancelled."
                exit 0
                ;;
        esac
    else
        echo "No changes to commit on main branch."
    fi
else
    if test_any_changes; then
        push_to_current_branch
    else
        echo "No changes to commit."
    fi
fi

echo "Done!"


