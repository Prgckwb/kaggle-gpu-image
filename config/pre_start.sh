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

# Claude Code: self-update on every pod start.
# Baked version is frozen by Docker layer cache; `claude update` keeps up
# with Anthropic's multi-release-per-week cadence. Non-fatal on network
# failure so offline pods still start.
if command -v claude >/dev/null 2>&1; then
    echo "Updating Claude Code..."
    before="$(claude -V 2>/dev/null || echo unknown)"
    if claude update >/dev/null 2>&1; then
        after="$(claude -V 2>/dev/null || echo unknown)"
        echo "Claude Code: $before -> $after"
    else
        echo "warning: claude update failed (continuing with $before)" >&2
    fi
fi

echo "=== pre_start.sh complete ==="
