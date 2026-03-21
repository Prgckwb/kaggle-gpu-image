#!/bin/bash
set -e

echo "=== Kaggle GPU Image: pre_start.sh ==="

# GitHub CLI auth from GITHUB_TOKEN env var
if [[ -n "$GITHUB_TOKEN" ]]; then
    echo "GITHUB_TOKEN detected. Configuring gh + git..."
    gh auth setup-git
    echo "GitHub CLI authenticated."
else
    echo "GITHUB_TOKEN not set. Skipping GitHub auth."
fi

# Git identity from env vars
[[ -n "$GIT_USER_NAME" ]]  && git config --global user.name "$GIT_USER_NAME"
[[ -n "$GIT_USER_EMAIL" ]] && git config --global user.email "$GIT_USER_EMAIL"

echo "=== pre_start.sh complete ==="
