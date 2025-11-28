# ==============================================================================
# justfile for macOS Environment Setup (Aggregated via Imports)
# ==============================================================================

set dotenv-load

# Shared logic (root level helpers if needed)
import 'ansible/ansible.just'

# ==============================================================================
# Role Imports
# ==============================================================================
# Recipes from each file are merged directly into this file

import 'ansible/roles/brew/tasks.just'
import 'ansible/roles/coderabbit/tasks.just'
import 'ansible/roles/docker/tasks.just'
import 'ansible/roles/editor/tasks.just'
import 'ansible/roles/gh/tasks.just'
import 'ansible/roles/menv/tasks.just'
import 'ansible/roles/nodejs/tasks.just'
import 'ansible/roles/python/tasks.just'
import 'ansible/roles/ruby/tasks.just'
import 'ansible/roles/rust/tasks.just'
import 'ansible/roles/shell/tasks.just'
import 'ansible/roles/ssh/tasks.just'
import 'ansible/roles/system/tasks.just'
import 'ansible/roles/vcs/tasks.just'

# ==============================================================================
# Variables
# ==============================================================================
repo_root := `pwd`
mlx_venv_path := repo_root / "venvs/mlx-lm"

# ==============================================================================
# Global / Alias Workflows
# ==============================================================================

default: help

# Display help with all available recipes
help:
  @echo "Usage: just [recipe]"
  @echo "Available recipes:"
  @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# Run all common setup tasks (Legacy Wrapper)
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
_find_shell_files:
  @find . -type f \( -name "*.sh" -o -name "*.bash" \) | \
  grep -v "\.git" | \
  grep -v "gemini.zsh" | \
  grep -v "\.uv-cache" | \
  grep -v "\.venv" | \
  grep -v "/venvs/"
