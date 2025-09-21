# ==============================================================================
# justfile for macOS Environment Setup
# ==============================================================================

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
repo_root := `pwd`
playbook := repo_root / "ansible/playbook.yml"
inventory := repo_root / "ansible/hosts"
config_common := "config/common"
config_macbook := "config/macbook-only"
config_mac_mini := "config/mac-mini-only"

# Show available recipes
default: help

# ------------------------------------------------------------------------------
# Common Setup Recipes
# ------------------------------------------------------------------------------
# Run all common setup tasks
common:
  @echo "🚀 Starting all common setup tasks..."
  @just cmn-shell
  @just cmn-apply-defaults
  @just cmn-git
  @just cmn-gh
  @just cmn-vscode
  @just cmn-python-platform
  @just cmn-python-tools
  @just cmn-nodejs-platform
  @just cmn-nodejs-tools
  @just cmn-cursor
  @just cmn-claude
  @just cmn-ruby
  @just cmn-java
  @just cmn-brew
  @echo "✅ All common setup tasks completed successfully."

# ------------------------------------------------------------------------------
# Common Setup Recipes
# ------------------------------------------------------------------------------
# Apply macOS system defaults
cmn-apply-defaults:
  @echo "🚀 Applying common system defaults..."
  @just _run_ansible "system_defaults" "{{config_common}}"

# Setup common Homebrew packages
cmn-brew:
  @echo "  -> Running Homebrew setup with config: {{config_common}}"
  @just _run_ansible "brew" "{{config_common}}"

# Configure GitHub CLI (gh) settings
cmn-gh:
  @echo "🚀 Running common GitHub CLI setup..."
  @just _run_ansible "gh" "{{config_common}}"

# Configure Git settings
cmn-git:
  @echo "🚀 Running common Git setup..."
  @just _run_ansible "git" "{{config_common}}"

# Setup Java environment
cmn-java:
  @echo "🚀 Running common Java setup..."
  @just _run_ansible "java" "{{config_common}}"

# Setup Node.js platform
cmn-nodejs-platform:
  @echo "🚀 Running common Node.js platform setup..."
  @just _run_ansible "nodejs-platform" "{{config_common}}"

# Install common Node.js tools
cmn-nodejs-tools:
  @echo "🚀 Installing common Node.js tools from config: {{config_common}}"
  @just _run_ansible "nodejs-tools" "{{config_common}}"

# Setup Python platform
cmn-python-platform:
  @echo "🚀 Running common Python platform setup..."
  @just _run_ansible "python-platform" "{{config_common}}"

# Install common Python tools
cmn-python-tools:
  @echo "🚀 Installing common Python tools from config: {{config_common}}"
  @just _run_ansible "python-tools" "{{config_common}}"

# Setup Ruby environment with rbenv
cmn-ruby:
  @echo "🚀 Running common Ruby setup..."
  @just _run_ansible "ruby" "{{config_common}}"

# Link common shell configuration files
cmn-shell:
  @echo "🚀 Linking common shell configuration..."
  @just _run_ansible "shell" "{{config_common}}"

# Setup VS Code settings and extensions
cmn-vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run_ansible "vscode" "{{config_common}}"

# Setup Cursor settings and CLI
cmn-cursor:
  @echo "🚀 Running common Cursor setup..."
  @just _run_ansible "cursor" "{{config_common}}"

# Setup Claude Code settings
cmn-claude:
  @echo "🚀 Running common Claude Code setup..."
  @just _run_ansible "claude" "{{config_common}}"

# Install common GUI applications (casks)
cmn-apps:
  @echo "🚀 Installing common GUI applications..."
  @brew install --cask \
    android-studio \
    android-commandlinetools \
    google-chrome \
    slack \
    zoom \
    obsidian \
    docker \
    pgadmin4 \
    tailscale \
    rectangle \
    cursor

# ------------------------------------------------------------------------------
# MacBook-Specific Recipes
# ------------------------------------------------------------------------------
# Install specific Homebrew packages
mbk-brew:
  @echo "  -> Running Homebrew setup with config: {{config_macbook}}"
  @just _run_ansible "brew" "{{config_macbook}}"

# Install MacBook-specific Node.js tools
mbk-nodejs-tools:
  @echo "🚀 Installing MacBook-specific Node.js tools from config: {{config_macbook}}"
  @just _run_ansible "nodejs-tools" "{{config_macbook}}"

# Install MacBook-specific Python tools
mbk-python-tools:
  @echo "🚀 Installing MacBook-specific Python tools from config: {{config_macbook}}"
  @just _run_ansible "python-tools" "{{config_macbook}}"

# ------------------------------------------------------------------------------
# Mac Mini-Specific Recipes
# ------------------------------------------------------------------------------
# Install specific Homebrew packages
mmn-brew:
  @echo "  -> Running Homebrew setup with config: {{config_mac_mini}}"
  @just _run_ansible "brew" "{{config_mac_mini}}"

# Install Mac Mini-specific Node.js tools
mmn-nodejs-tools:
  @echo "🚀 Installing Mac Mini-specific Node.js tools from config: {{config_mac_mini}}"
  @just _run_ansible "nodejs-tools" "{{config_mac_mini}}"

# Install Mac Mini-specific Python tools
mmn-python-tools:
  @echo "🚀 Installing Mac Mini-specific Python tools from config: {{config_mac_mini}}"
  @just _run_ansible "python-toolsa" "{{config_mac_mini}}"

# Install Mac Mini-specific GUI applications (casks)
mmn-apps:
  @echo "🚀 Installing Mac Mini-specific GUI applications..."
  @brew install --cask ngrok

# ------------------------------------------------------------------------------
# Utility Recipes
# ------------------------------------------------------------------------------
# Backup current macOS system defaults
cmn-backup-defaults:
  @echo "🚀 Backing up current macOS system defaults..."
  @{{repo_root}}/ansible/utils/backup-system-defaults.sh "{{config_common}}"
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
_run_ansible tags config_dir:
  @if [ ! -f .env ]; then echo "❌ Error: .env file not found. Please run 'make setup' first."; exit 1; fi && \
  export $(grep -v '^#' .env | xargs) && \
  export ANSIBLE_CONFIG={{repo_root}}/ansible/ansible.cfg && \
  ~/.local/pipx/venvs/ansible/bin/ansible-playbook -i {{inventory}} {{playbook}} --tags "{{tags}}" -e "config_dir_abs_path={{repo_root}}/{{config_dir}}"
