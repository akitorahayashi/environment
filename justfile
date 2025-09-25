# ==============================================================================
# justfile for macOS Environment Setup
# ==============================================================================

set dotenv-load

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
repo_root := `pwd`
playbook := repo_root / "ansible/playbook.yml"
inventory := repo_root / "ansible/hosts"
config_common := "config/common"
config_macbook := "config/profiles/macbook"
config_mac_mini := "config/profiles/mac-mini"


# Show available recipes
default: help

# ------------------------------------------------------------------------------
# Common Setup Recipes
# ------------------------------------------------------------------------------
# Run all common setup tasks
common:
  @echo "🚀 Starting all common setup tasks..."
  @just cmn-shell
  @just cmn-ssh
  @just cmn-apply-system
  @just cmn-git
  @just cmn-jj
  @just cmn-gh
  @just sw-p
  @just cmn-vscode
  @just cmn-python-platform
  @just cmn-python-tools
  @just cmn-nodejs-platform
  @just cmn-nodejs-tools
  @just cmn-cld
  @just cmn-gm
  @just cmn-mcp
  @just cmn-cursor
  @just cmn-ruby

  @just cmn-aider
  @just cmn-formulae
  @echo "✅ All common setup tasks completed successfully."

# ------------------------------------------------------------------------------
# Common Setup Recipes
# ------------------------------------------------------------------------------
# Apply macOS system defaults
cmn-apply-system:
  @echo "🚀 Applying common system defaults..."
  @just _run_ansible "system" "common"

# Setup common Homebrew formulae packages
cmn-formulae:
  @echo "  -> Running Homebrew formulae setup with config: {{config_common}}/brew"
  @just _run_ansible "formulae" "common"

# Configure Git settings
cmn-git:
  @echo "🚀 Running common Git setup..."
  @just _run_ansible "git" "common"

# Configure JJ (Jujutsu) settings
cmn-jj:
  @echo "🚀 Running common JJ setup..."
  @just _run_ansible "jj" "common"

# Configure GitHub CLI settings
cmn-gh:
  @echo "🚀 Running GitHub CLI setup..."
  @just _run_ansible "gh" "common"

# Setup Node.js platform
cmn-nodejs-platform:
  @echo "🚀 Running common Node.js platform setup..."
  @just _run_ansible "nodejs-platform" "common"

# Install common Node.js tools
cmn-nodejs-tools:
  @echo "🚀 Installing common Node.js tools from config: {{config_common}}/languages"
  @just _run_ansible "nodejs-tools" "common"

# Setup Python platform
cmn-python-platform:
  @echo "🚀 Running common Python platform setup..."
  @just _run_ansible "python-platform" "common"

# Install common Python tools
cmn-python-tools:
  @echo "🚀 Installing common Python tools from config: {{config_common}}/languages"
  @just _run_ansible "python-tools" "common"

# Setup Ruby environment with rbenv
cmn-ruby:
  @echo "🚀 Running common Ruby setup..."
  @just _run_ansible "ruby" "common"

# Link common shell configuration files
cmn-shell:
  @echo "🚀 Linking common shell configuration..."
  @just _run_ansible "shell" "common"

# Setup SSH configuration
cmn-ssh:
  @echo "🚀 Running common SSH setup..."
  @just _run_ansible "ssh" "common"

# Setup VS Code settings and extensions
cmn-vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run_ansible "vscode" "common"

# Setup Cursor settings and CLI
cmn-cursor:
  @echo "🚀 Running common Cursor setup..."
  @just _run_ansible "cursor" "common"

# Setup Claude Code settings
cmn-cld:
  @echo "🚀 Running common Claude Code setup..."
  @just _run_ansible "claude" "common"

# Setup Gemini CLI settings
cmn-gm:
  @echo "🚀 Running common Gemini CLI setup..."
  @just _run_ansible "gemini" "common"

# Setup MCP servers configuration
cmn-mcp:
  @echo "🚀 Running common MCP setup..."
  @just _run_ansible "mcp" "common"

# Install Aider Chat
cmn-aider:
  @echo "🚀 Running common Aider setup..."
  @just _run_ansible "aider" "common"


# Install common cask
cmn-cask:
  @echo "🚀 Installing common Brew Casks..."
  @just _run_ansible "cask" "common"

# Pull Docker images
cmn-docker-images:
  @echo "🚀 Checking/verifying Docker images..."
  @just _run_ansible "docker" "common"

# ------------------------------------------------------------------------------
# MacBook-Specific Recipes
# ------------------------------------------------------------------------------
# Install MacBook-specific cask
mbk-cask:
  @echo "🚀 Installing MacBook-specific Brew Casks..."
  @just _run_ansible "cask" "macbook"

# ------------------------------------------------------------------------------
# Mac Mini-Specific Recipes
# ------------------------------------------------------------------------------

mmn-cask:
  @echo "🚀 Installing Mac Mini-specific Brew Casks..."
  @just _run_ansible "cask" "mac-mini"

# ------------------------------------------------------------------------------
# VCS Profile Switching
# ------------------------------------------------------------------------------
sw-p:
  @echo "🔄 Switching to personal configuration..."
  @git config --global user.name "{{env('PERSONAL_VCS_NAME')}}"
  @git config --global user.email "{{env('PERSONAL_VCS_EMAIL')}}"
  @[ -n "{{env('PERSONAL_VCS_NAME')}}" ] || (echo "PERSONAL_VCS_NAME is empty" >&2; exit 1)
  @[ -n "{{env('PERSONAL_VCS_EMAIL')}}" ] || (echo "PERSONAL_VCS_EMAIL is empty" >&2; exit 1)
  @echo "1" | jj config set --user user.name "{{env('PERSONAL_VCS_NAME')}}"
  @echo "1" | jj config set --user user.email "{{env('PERSONAL_VCS_EMAIL')}}"
  @echo "✅ Switched to personal configuration."
  @echo "Git user: `git config --get user.name` <`git config --get user.email`>"
  @echo "jj  user: `jj config get user.name` <`jj config get user.email`>"

sw-w:
  @echo "🔄 Switching to work configuration..."
  @git config --global user.name "{{env('WORK_VCS_NAME')}}"
  @git config --global user.email "{{env('WORK_VCS_EMAIL')}}"
  @[ -n "{{env('WORK_VCS_NAME')}}" ] || (echo "WORK_VCS_NAME is empty" >&2; exit 1)
  @[ -n "{{env('WORK_VCS_EMAIL')}}" ] || (echo "WORK_VCS_EMAIL is empty" >&2; exit 1)
  @echo "1" | jj config set --user user.name "{{env('WORK_VCS_NAME')}}"
  @echo "1" | jj config set --user user.email "{{env('WORK_VCS_EMAIL')}}"
  @echo "✅ Switched to work configuration."
  @echo "Git user: `git config --get user.name` <`git config --get user.email`>"
  @echo "jj  user: `jj config get user.name` <`jj config get user.email`>"

# ------------------------------------------------------------------------------
# Utility Recipes
# ------------------------------------------------------------------------------
# Backup current macOS system defaults
cmn-backup-system:
  @echo "🚀 Backing up current macOS system defaults..."
  @{{repo_root}}/ansible/utils/backup-system.sh "{{config_common}}"
  @echo "✅ macOS system defaults backup completed."

# Backup current VSCode extensions
cmn-backup-vscode-extensions:
  @echo "🚀 Backing up current VSCode extensions..."
  @{{repo_root}}/ansible/utils/backup-extensions.sh "{{config_common}}"
  @echo "✅ VSCode extensions backup completed."

# Display help with all available recipes
help:
  @echo "Usage: just [recipe]"
  @echo "Available recipes:"
  @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# ------------------------------------------------------------------------------
# Hidden Recipes
# ------------------------------------------------------------------------------
# @hidden
_run_ansible tags profile:
  @if [ ! -f .env ]; then echo "❌ Error: .env file not found. Please run 'make base' first."; exit 1; fi && \
  export $(grep -v '^#' .env | xargs) && \
  export ANSIBLE_CONFIG={{repo_root}}/ansible/ansible.cfg && \
  ~/.local/pipx/venvs/ansible/bin/ansible-playbook -i {{inventory}} {{playbook}} --tags "{{tags}}" -e "config_dir_abs_path={{repo_root}}/config/common" -e "profile={{profile}}" -e "repo_root_path={{repo_root}}"
