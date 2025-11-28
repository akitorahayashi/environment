# ==============================================================================
# justfile for macOS Environment Setup
# ==============================================================================

set dotenv-load

# ==============================================================================
# Variables
# ==============================================================================
repo_root := `pwd`
playbook := repo_root / "ansible/playbook.yml"
inventory := repo_root / "ansible/hosts"
menv_dir := repo_root
mlx_venv_path := menv_dir / "venvs/mlx-lm"


# Show available recipes
default: help

# Display help with all available recipes
help:
  @echo "Usage: just [recipe]"
  @echo "Available recipes:"
  @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'
  
# ==============================================================================
# Common Setup Recipes
# ==============================================================================
# Run all common setup tasks
common:
  @echo "🚀 Starting all common setup tasks..."
  @just shell
  @just menv
  @just ssh
  @just apply-system
  @just git
  @just jj
  @just gh
  @just sw-p
  @just vscode
  @just python
  @just uv
  @just nodejs
  @just cursor
  @just coderabbit
  @just ruby
  @just rust
  @just brew-formulae
  @echo "✅ All common setup tasks completed successfully."

# ==============================================================================
# Common Setup Recipes
# ==============================================================================
# Apply macOS system defaults
apply-system:
  @echo "🚀 Applying common system defaults..."
  @just _run_ansible "system" "common" "system"

# Setup common Homebrew formulae packages only
brew-formulae:
  @echo "  -> Running Homebrew formulae setup with config: ansible/roles/brew/config"
  @just _run_ansible "brew" "common" "brew-formulae"

# Configure Git settings only
git:
  @echo "🚀 Running common Git setup..."
  @just _run_ansible "vcs" "common" "git"

# Configure JJ (Jujutsu) settings only
jj:
  @echo "🚀 Running common JJ setup..."
  @just _run_ansible "vcs" "common" "jj"

# Configure GitHub CLI settings
gh:
  @echo "🚀 Running GitHub CLI setup..."
  @just _run_ansible "gh" "common" "gh"

# Setup Node.js platform and tools
nodejs:
  @echo "🚀 Running common Node.js setup..."
  @just nodejs-platform
  @just nodejs-tools
  @just llm

# Setup Node.js platform only
nodejs-platform:
  @echo "🚀 Running common Node.js platform setup..."
  @just _run_ansible "nodejs" "common" "nodejs-platform"

# Install Node.js tools only
nodejs-tools:
  @echo "🚀 Installing common Node.js tools from config: ansible/roles/nodejs/config/common"
  @just _run_ansible "nodejs" "common" "nodejs-tools"

# Setup Python platform and tools
python:
  @echo "🚀 Running common Python setup..."
  @just python-platform
  @just python-tools
  @just aider

# Setup Python platform only
python-platform:
  @echo "🚀 Running common Python platform setup..."
  @just _run_ansible "python" "common" "python-platform"

# Install Python tools only
python-tools:
  @echo "🚀 Installing common Python tools from config: ansible/roles/python/config/common"
  @just _run_ansible "python" "common" "python-tools"

# Setup Ruby environment with rbenv
ruby:
  @echo "🚀 Running common Ruby setup..."
  @just _run_ansible "ruby" "common" "ruby"

# Setup Rust environment with rustup and tools
rust:
  @echo "🚀 Running common Rust setup..."
  @just rust-platform
  @just rust-tools

# Setup Rust platform only
rust-platform:
  @echo "🚀 Running common Rust platform setup..."
  @just _run_ansible "rust" "common" "rust-platform"

# Install Rust tools only
rust-tools:
  @echo "🚀 Installing common Rust tools from config: ansible/roles/rust/config/common"
  @just _run_ansible "rust" "common" "rust-tools"

# Link common shell configuration files
shell:
  @echo "🚀 Linking common shell configuration..."
  @just _run_ansible "shell" "common" "shell"

# Install menv convenience wrapper
menv:
  @echo "🚀 Installing menv command wrapper..."
  @just _run_ansible "menv" "common" "menv"

# Setup SSH configuration
ssh:
  @echo "🚀 Running common SSH setup..."
  @just _run_ansible "ssh" "common" "ssh"

# Setup VS Code settings and extensions
vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run_ansible "editor" "common" "vscode"

# Setup Cursor settings and CLI
cursor:
  @echo "🚀 Running common Cursor setup..."
  @just _run_ansible "editor" "common" "cursor"

# Setup CodeRabbit CLI
coderabbit:
  @echo "🚀 Running common CodeRabbit setup..."
  @just _run_ansible "coderabbit" "common" "coderabbit"

# Setup Node.js based LLM tools (Claude, Gemini, Codex)
llm:
  @echo "🚀 Setting up Node.js LLM tools..."
  @just _run_ansible "nodejs" "common" "llm"

# Setup Aider configuration
aider:
  @echo "🚀 Running common Aider setup..."
  @just _run_ansible "python" "common" "aider"

# Setup uv configuration
uv:
  @echo "🚀 Running common uv setup..."
  @just _run_ansible "python" "common" "uv"

# Install common cask packages only
brew-cask:
  @echo "🚀 Installing common Brew Casks..."
  @just _run_ansible "brew" "common" "brew-cask"

# Pull Docker images
docker-images:
  @echo "🚀 Checking/verifying Docker images..."
  @just _run_ansible "docker" "common" "docker"

# ==============================================================================
# MacBook-Specific Recipes
# ==============================================================================
# Install MacBook-specific cask
mbk-brew-cask:
  @echo "🚀 Installing MacBook-specific Brew Casks..."
  @just _run_ansible "brew" "macbook" "brew-cask"

# ==============================================================================
# Mac Mini-Specific Recipes
# ==============================================================================
# Install Mac Mini-specific cask packages
mmn-brew-cask:
  @echo "🚀 Installing Mac Mini-specific Brew Casks..."
  @just _run_ansible "brew" "mac-mini" "brew-cask"

# ==============================================================================
# VCS Profile Switching
# ==============================================================================
# Switch to personal VCS configuration
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

# Switch to work VCS configuration
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

# ==============================================================================
# Utility Recipes
# ==============================================================================
# Backup current macOS system defaults
backup-system:
  @echo "🚀 Backing up current macOS system defaults..."
  @{{repo_root}}/ansible/scripts/system/backup-system.py "{{repo_root}}/ansible/roles/system/config/common"
  @echo "✅ macOS system defaults backup completed."

# Backup current VSCode extensions
backup-vscode-extensions:
  @echo "🚀 Backing up current VSCode extensions..."
  @{{repo_root}}/ansible/scripts/editor/backup-extensions.py "{{repo_root}}/ansible/roles/editor/config/common"
  @echo "✅ VSCode extensions backup completed."

# ==============================================================================
# CODE QUALITY
# ==============================================================================

# Format code with black and ruff --fix
format:
  @echo "Formatting code with black, ruff, shfmt, and ansible-lint..."
  @uv run black tests/ ansible/
  @uv run ruff check tests/ ansible/ --fix
  @files=$(just _find_shell_files); \
  echo "Found $(echo "$files" | wc -l) shell files to format"; \
  for file in $files; do \
      shfmt -w -d "$file" 2>/dev/null || echo "Formatted: $file"; \
  done
  @uv run ansible-lint ansible/ --fix

# Lint code with black check, ruff, shellcheck, and ansible-lint
lint:
  @echo "Linting code with black check, ruff, shellcheck, and ansible-lint..."
  @uv run black --check tests/ ansible/
  @uv run ruff check tests/ ansible/
  @files=$(just _find_shell_files); \
  echo "Found $(echo "$files" | wc -l) shell files to lint"; \
  for file in $files; do \
      shellcheck "$file" 2>/dev/null || echo "Issues found in: $file"; \
  done
  @uv run ansible-lint ansible/
    
# ==============================================================================
# Testing
# ==============================================================================
# Run all tests under tests/ directory with pytest
test:
  @echo "🧪 Running all tests under tests/ directory..."
  @uv run pytest tests/

# ==============================================================================
# CLEANUP
# ==============================================================================

# Remove __pycache__ and .venv to make project lightweight
clean:
  @echo "🧹 Cleaning up project..."
  @find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
  @rm -rf .venv
  @rm -rf {{mlx_venv_path}}
  @rm -rf venvs
  @rm -rf .pytest_cache
  @rm -rf .ruff_cache
  @rm -rf .aider.tags.cache.v4
  @rm -rf .serena/cache
  @rm -rf .uv-cache
  @rm -rf .tmp
  @echo "✅ Cleanup completed"

# ==============================================================================
# Hidden Recipes
# ==============================================================================
# @hidden
_run_ansible role profile tag *args="":
  @if [ ! -f .env ]; then echo "❌ Error: .env file not found. Please run 'make base' first."; exit 1; fi && \
  export $(grep -v '^#' .env | xargs) && \
  export ANSIBLE_CONFIG={{repo_root}}/ansible/ansible.cfg && \
  uv run ansible-playbook -i {{inventory}} {{playbook}} --limit localhost --tags "{{tag}}" -e "profile={{profile}}" -e "repo_root_path={{repo_root}}" {{args}}

# @hidden
_find_shell_files:
  @find . -type f \( -name "*.sh" -o -name "*.bash" \) | \
  grep -v "\.git" | \
  grep -v "gemini.zsh" | \
  grep -v "\.uv-cache" | \
  grep -v "\.venv" | \
  grep -v "/venvs/"
