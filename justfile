# ==============================================================================
# justfile for macOS Environment Setup
# ==============================================================================

# ------------------------------------------------------------------------------
# Variables
# ------------------------------------------------------------------------------
repo_root := `pwd`
script_dir := repo_root / "scripts"
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
  @just cmn-python-platform
  @just cmn-python-tools
  @just cmn-nodejs-platform
  @just cmn-nodejs-tools
  @just cmn-vscode
  @just cmn-ruby
  @just cmn-brew
  @just cmn-flutter
  @just cmn-java
  @echo "✅ All common setup tasks completed successfully."

# ------------------------------------------------------------------------------
# Common Setup Recipes
# ------------------------------------------------------------------------------
# Apply macOS system defaults
cmn-apply-defaults:
  @echo "🚀 Applying common system defaults..."
  @just _run-script "system-defaults/apply-system-defaults.sh" "{{config_common}}"

# Setup common Homebrew packages
cmn-brew:
  @echo "  -> Running Homebrew setup with config: {{config_common}}"
  @just _run-script "brew.sh" "{{config_common}}"

# Setup Flutter environment
cmn-flutter:
  @echo "🚀 Running common Flutter setup..."
  @just _run-script "flutter.sh" "{{config_common}}"

# Configure GitHub CLI (gh) settings
cmn-gh:
  @echo "🚀 Running common GitHub CLI setup..."
  @just _run-script "gh.sh" "{{config_common}}"

# Configure Git settings
cmn-git:
  @echo "🚀 Running common Git setup..."
  @just _run-script-with-env "git.sh" "{{config_common}}"

# Setup Java environment
cmn-java:
  @echo "🚀 Running common Java setup..."
  @just _run-script "java.sh" "{{config_common}}"

# Setup Node.js platform
cmn-nodejs-platform:
  @echo "🚀 Running common Node.js platform setup..."
  @just _run-script "nodejs/platform.sh" "{{config_common}}"

# Install common Node.js tools
cmn-nodejs-tools:
  @echo "🚀 Installing common Node.js tools from config: {{config_common}}"
  @just _run-script "nodejs/tools.sh" "{{config_common}}"

# Setup Python platform
cmn-python-platform:
  @echo "🚀 Running common Python platform setup..."
  @just _run-script "python/platform.sh" "{{config_common}}"

# Install common Python tools
cmn-python-tools:
  @echo "🚀 Installing common Python tools from config: {{config_common}}"
  @just _run-script "python/tools.sh" "{{config_common}}"

# Setup Ruby environment with rbenv
cmn-ruby:
  @echo "🚀 Running common Ruby setup..."
  @just _run-script "ruby.sh" "{{config_common}}"

# Link common shell configuration files
cmn-shell:
  @echo "🚀 Linking common shell configuration..."
  @just _run-script "shell.sh" "{{config_common}}"

# Setup VS Code settings and extensions
cmn-vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run-script "vscode.sh" "{{config_common}}"

# ------------------------------------------------------------------------------
# MacBook-Specific Recipes
# ------------------------------------------------------------------------------
# Install specific Homebrew packages
mbk-brew-specific:
  @echo "  -> Running Homebrew setup with config: {{config_macbook}}"
  @just _run-script "brew.sh" "{{config_macbook}}"

# Install MacBook-specific Node.js tools
mbk-nodejs-tools:
  @echo "🚀 Installing MacBook-specific Node.js tools from config: {{config_macbook}}"
  @just _run-script "nodejs/tools.sh" "{{config_macbook}}"

# Install MacBook-specific Python tools
mbk-python-tools:
  @echo "🚀 Installing MacBook-specific Python tools from config: {{config_macbook}}"
  @just _run-script "python/tools.sh" "{{config_macbook}}"

# ------------------------------------------------------------------------------
# Mac Mini-Specific Recipes
# ------------------------------------------------------------------------------
# Install specific Homebrew packages
mmn-brew-specific:
  @echo "  -> Running Homebrew setup with config: {{config_mac_mini}}"
  @just _run-script "brew.sh" "{{config_mac_mini}}"

# ------------------------------------------------------------------------------
# Utility Recipes
# ------------------------------------------------------------------------------
# Backup current macOS system defaults
cmn-backup-defaults:
  @echo "🚀 Backing up current macOS system defaults..."
  @just _run-script "system-defaults/backup-system-defaults.sh" "{{config_common}}"
  @echo "✅ macOS system defaults backup completed."

# Display help with all available recipes
help:
  @echo "Usage: just [recipe]"
  @echo "Available recipes:"
  @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# ------------------------------------------------------------------------------
# Hidden Recipes
# ------------------------------------------------------------------------------
# @hidden
_run-script-with-env script_path config_dir:
  bash -euo pipefail "{{script_dir}}/{{script_path}}" "{{repo_root}}/{{config_dir}}" "{{repo_root}}/.env"

# @hidden
_run-script script_path config_dir:
  bash -euo pipefail "{{script_dir}}/{{script_path}}" "{{repo_root}}/{{config_dir}}"
