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

# Category-specific paths
brew_path := config_common / "brew"
aiding_path := config_common / "aiding"
editors_path := config_common / "editors"
languages_path := config_common / "languages"
vcs_path := config_common / "vcs"
shell_path := config_common / "shell"
ssh_path := config_common / "ssh"
system_path := config_common / "system"
mcp_path := config_common / "mcp"
docker_path := config_common / "docker"

# Machine-specific brew paths
macbook_brew_path := config_macbook / "brew"
mac_mini_brew_path := config_mac_mini / "brew"

# Machine-specific apps paths
macbook_apps_path := config_macbook / "apps"
mac_mini_apps_path := config_mac_mini / "apps"

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
  @just cmn-java
  @just cmn-aider
  @just cmn-brew
  @echo "✅ All common setup tasks completed successfully."

# ------------------------------------------------------------------------------
# Common Setup Recipes
# ------------------------------------------------------------------------------
# Apply macOS system defaults
cmn-apply-system:
  @echo "🚀 Applying common system defaults..."
  @just _run_ansible "system" "{{system_path}}"

# Setup common Homebrew packages
cmn-brew:
  @echo "  -> Running Homebrew setup with config: {{brew_path}}"
  @just _run_ansible "brew" "{{brew_path}}"

# Configure Git settings
cmn-git:
  @echo "🚀 Running common Git setup..."
  @just _run_ansible "git" "{{vcs_path}}"

# Configure JJ (Jujutsu) settings
cmn-jj:
  @echo "🚀 Running common JJ setup..."
  @just _run_ansible "jj" "{{vcs_path}}"

# Setup Java environment
cmn-java:
  @echo "🚀 Running common Java setup..."
  @just _run_ansible "java" "{{config_common}}"

# Setup Node.js platform
cmn-nodejs-platform:
  @echo "🚀 Running common Node.js platform setup..."
  @just _run_ansible "nodejs-platform" "{{languages_path}}"

# Install common Node.js tools
cmn-nodejs-tools:
  @echo "🚀 Installing common Node.js tools from config: {{languages_path}}"
  @just _run_ansible "nodejs-tools" "{{languages_path}}"

# Setup Python platform
cmn-python-platform:
  @echo "🚀 Running common Python platform setup..."
  @just _run_ansible "python-platform" "{{languages_path}}"

# Install common Python tools
cmn-python-tools:
  @echo "🚀 Installing common Python tools from config: {{languages_path}}"
  @just _run_ansible "python-tools" "{{languages_path}}"

# Setup Ruby environment with rbenv
cmn-ruby:
  @echo "🚀 Running common Ruby setup..."
  @just _run_ansible "ruby" "{{languages_path}}"

# Link common shell configuration files
cmn-shell:
  @echo "🚀 Linking common shell configuration..."
  @just _run_ansible "shell" "{{shell_path}}"

# Setup SSH configuration
cmn-ssh:
  @echo "🚀 Running common SSH setup..."
  @just _run_ansible "ssh" "{{ssh_path}}"

# Setup VS Code settings and extensions
cmn-vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run_ansible "vscode" "{{editors_path}}"

# Setup Cursor settings and CLI
cmn-cursor:
  @echo "🚀 Running common Cursor setup..."
  @just _run_ansible "cursor" "{{editors_path}}"

# Setup Claude Code settings
cmn-cld:
  @echo "🚀 Running common Claude Code setup..."
  @just _run_ansible "claude" "{{aiding_path}}"

# Setup Gemini CLI settings
cmn-gm:
  @echo "🚀 Running common Gemini CLI setup..."
  @just _run_ansible "gemini" "{{aiding_path}}"

# Setup MCP servers configuration
cmn-mcp:
  @echo "🚀 Running common MCP setup..."
  @just _run_ansible "mcp" "{{mcp_path}}"

# Install Aider Chat
cmn-aider:
  @echo "🚀 Running common Aider setup..."
  @just _run_ansible "aider" "{{aiding_path}}"


# Install common GUI applications (casks)
cmn-apps:
  @echo "🚀 Installing common GUI applications..."
  @just _run_ansible "apps" "{{pkg_path}}"

# Pull Docker images
cmn-docker-images:
  @echo "🚀 Checking/verifying Docker images..."
  @just _run_ansible "docker" "{{docker_path}}"

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
  @echo "🚀 Running Homebrew setup with config: {{config_mac_mini}}"
  @just _run_ansible "brew" "{{config_mac_mini}}"

# Install Mac Mini-specific Node.js tools
mmn-nodejs-tools:
  @echo "🚀 Installing Mac Mini-specific Node.js tools from config: {{config_mac_mini}}"
  @just _run_ansible "nodejs-tools" "{{config_mac_mini}}"

# Install Mac Mini-specific Python tools
mmn-python-tools:
  @echo "🚀 Installing Mac Mini-specific Python tools from config: {{config_mac_mini}}"
  @just _run_ansible "python-tools" "{{config_mac_mini}}"

# Install Mac Mini-specific GUI applications (casks)
mmn-apps:
  @echo "🚀 Installing Mac Mini-specific GUI applications..."
  @just _run_ansible "apps" "{{config_mac_mini}}"

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
_run_ansible tags config_dir:
  @if [ ! -f .env ]; then echo "❌ Error: .env file not found. Please run 'make base' first."; exit 1; fi && \
  export $(grep -v '^#' .env | xargs) && \
  export ANSIBLE_CONFIG={{repo_root}}/ansible/ansible.cfg && \
  ~/.local/pipx/venvs/ansible/bin/ansible-playbook -i {{inventory}} {{playbook}} --tags "{{tags}}" -e "config_dir_abs_path={{repo_root}}/{{config_dir}}" -e "repo_root_path={{repo_root}}" -e "repo_root_path={{repo_root}}"
