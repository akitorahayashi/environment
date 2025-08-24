#!/bin/bash
set -euo pipefail

if [ -z "${REPO_ROOT:-}" ]; then
    echo "[ERROR] REPO_ROOT environment variable is not set. This script should be run via 'make'." >&2
    exit 1
fi

# ================================================
# GitHub CLI (gh) のインストールと設定
# ================================================
#
# 1. gh のインストール (Homebrew経由)
# 2. gh のエイリアス設定
#
# ================================================

echo "🚀 Setting up GitHub CLI (gh)..."

# 1. gh のインストール
echo "[INFO] Checking and installing GitHub CLI (gh) if not present..."
if ! command -v gh &> /dev/null; then
    echo "[INFO] gh not found. Installing via Homebrew..."
    brew install gh
    echo "[SUCCESS] gh installed successfully."
else
    echo "[INFO] gh is already installed."
fi

# 2. gh のエイリアス設定
echo "[INFO] Setting up gh aliases..."

# gh repo aliases
gh alias set re-ls "repo list --json name | jq -r '.[].name'" --clobber
gh alias set re-cl 'repo clone' --clobber
gh alias set re-cr '!f() { local name="$1"; local desc="$2"; local is_public="$3"; if [ -z "$name" ]; then echo "Usage: gh re-cr <repo-name> [description] [public(true/false)]" >&2; return 1; fi; if [ "$is_public" = "false" ]; then gh repo create "$name" --description "${desc:-}" --private; else gh repo create "$name" --description "${desc:-}" --public; fi; }; f "$@"' --clobber

# gh pr aliases
gh alias set pr-create '!f() { local branch="$1"; local title="$2"; local body="$3"; if [ -z "$branch" ] || [ -z "$title" ]; then echo "Usage: gh pr-create <branch> <title> [body]" >&2; return 1; fi; gh pr create --head "$branch" --title "$title" --body "${body:-}" --fill; }; f "$@"' --clobber
gh alias set pr-ls '!f() { gh pr list --limit 20 --json number,title,author,headRefName,state --jq ".[] | {number, title, author: .author.login, branch: .headRefName, state}" | while read -r pr; do num=$(echo "$pr" | jq -r ".number"); branch=$(echo "$pr" | jq -r ".branch"); mergeable=$(gh pr view "$num" --json mergeable --jq ".mergeable"); running=$(gh run list --branch "$branch" --status in_progress --limit 1 --json databaseId | jq "length"); has_running_actions=$([ "$running" -gt 0 ] && echo "true" || echo "false"); echo "$pr" | jq --arg mergeable "$mergeable" --arg has_running "$has_running_actions" ". + {mergeable: $mergeable, actions_in_progress: $has_running}"; done; }; f' --clobber
gh alias set pr-mr '!f() { local pr_id="$1"; if [ -z "$pr_id" ]; then echo "Usage: gh pr-mr <pr-number>" >&2; return 1; fi; local mergeable; mergeable=$(gh pr view "$pr_id" --json mergeable --jq ".mergeable"); if [ "$mergeable" = "MERGEABLE" ]; then echo "PR #$pr_id is MERGEABLE. Merging..."; gh pr merge "$pr_id"; else echo "PR #$pr_id is not mergeable: $mergeable"; return 2; fi; }; f "$@"' --clobber

# gh run aliases
gh alias set r-ls "run list" --clobber
gh alias set r-w 'run watch' --clobber
gh alias set r-ce 'run cancel' --clobber
gh alias set r-w-f '!f() { id=$(gh run list --jq '\''select(.status=="in_progress") | .databaseId'\'' | head -n1); if [ -n "$id" ]; then echo "Watching workflow run $id ..."; gh run watch "$id"; else echo "No in_progress workflow found."; fi; }; f' --clobber

# gh branch aliases
gh alias set br-url '!f() { local remote_url branch repo_url; remote_url=$(git config --get remote.origin.url); branch=$(git rev-parse --abbrev-ref HEAD); repo_url=$(echo "$remote_url" | sed -E "s#git@github.com:(.*)\\.git#https://github.com/\\1#; s#https://github.com/#https://github.com/#; s#\\.git$##"); echo "${repo_url}/tree/${branch}"; }; f' --clobber

# gh copy file content alias
gh alias set cp-f '!f() { if [ -z "$1" ]; then echo "Usage: gh cp-f <GitHub file URL>"; return 1; fi; raw_url=$(echo "$1" | sed -E "s#https://github.com/([^/]+)/([^/]+)/blob/([^/]+)/(.*)#https://raw.githubusercontent.com/\\1/\\2/\\3/\\4#"); curl -sL "$raw_url" | pbcopy; echo "File content copied to clipboard ✅"; }; f "$@"' --clobber

echo "[SUCCESS] gh aliases set up."

# Verification step
echo ""
echo "==== Start: Verifying gh setup... ===="
verification_failed=false

# gh command verification
if ! command -v gh &> /dev/null; then
    echo "[ERROR] gh command is not available."
    verification_failed=true
else
    echo "[SUCCESS] gh command is available: $(gh --version)"
fi

# Alias verification
if ! gh alias list | grep -q "re-ls"; then
    echo "[ERROR] gh alias 're-ls' was not set correctly."
    verification_failed=true
else
    echo "[SUCCESS] gh alias 're-ls' is set."
fi

if [ "${verification_failed}" = "true" ]; then
    echo "❌ gh setup verification failed."
    exit 1
else
    echo "✅ gh setup verified successfully."
fi
