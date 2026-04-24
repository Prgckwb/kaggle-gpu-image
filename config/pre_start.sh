#!/bin/bash
set -e

echo "=== Kaggle GPU Image: pre_start.sh ==="

# GitHub CLI auth: prefer GH_TOKEN, fallback to GITHUB_TOKEN.
# Non-fatal: auth setup failure must not kill pod startup.
if [[ -n "${GH_TOKEN:-}" || -n "${GITHUB_TOKEN:-}" ]]; then
    echo "GitHub token detected. Configuring gh + git..."
    if gh auth setup-git; then
        echo "GitHub CLI authenticated."
    else
        echo "warning: gh auth setup-git failed (continuing anyway)" >&2
    fi
else
    echo "No GitHub token (GH_TOKEN / GITHUB_TOKEN). Skipping GitHub auth."
fi

# Git identity from env vars
[[ -n "${GIT_USER_NAME:-}" ]]  && git config --global user.name  "$GIT_USER_NAME"
[[ -n "${GIT_USER_EMAIL:-}" ]] && git config --global user.email "$GIT_USER_EMAIL"

echo "=== pre_start.sh complete ==="
