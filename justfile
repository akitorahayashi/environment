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
  @echo "🚀 Starting all common setup tasks (via Ansible)..."
  @just _run_ansible "shell,system_defaults,git,gh,python-platform,python-tools,nodejs-platform,nodejs-tools,vscode,ruby,brew,java,flutter" "{{config_common}}"
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

# Setup Flutter environment
cmn-flutter:
  @echo "🚀 Running common Flutter setup..."
  @just _run_ansible "flutter" "{{config_common}}" # (Assuming a 'flutter' role is created)

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

# ------------------------------------------------------------------------------
# MacBook-Specific Recipes
# ------------------------------------------------------------------------------
# Install specific Homebrew packages
mbk-brew-specific:
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
mmn-brew-specific:
  @echo "  -> Running Homebrew setup with config: {{config_mac_mini}}"
  @just _run_ansible "brew" "{{config_mac_mini}}"

# ------------------------------------------------------------------------------
# Utility Recipes
# ------------------------------------------------------------------------------
# Backup current macOS system defaults
cmn-backup-defaults:
  @echo "🚀 Backing up current macOS system defaults..."
  @{{repo_root}}/ansible/utils/backup-system-defaults.sh "{{config_common}}"
  @echo "✅ macOS system defaults backup completed."

# Display help with all available recipes
help:
  @echo "Usage: just [recipe]"
  @echo "Available recipes:"
  @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# ------------------------------------------------------------------------------
# Hidden Recipes
# ------------------------------------------------------------------------------
@hidden
_run_ansible tags config_dir:
  @export $(grep -v '^#' .env | xargs) && \
  @export ANSIBLE_CONFIG={{repo_root}}/ansible/ansible.cfg && \
  ansible-playbook -i {{inventory}} {{playbook}} --tags "{{tags}}" -e "config_dir_abs_path={{repo_root}}/{{config_dir}}"
