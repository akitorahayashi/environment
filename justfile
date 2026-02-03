# ==============================================================================
# justfile for menv development
# ==============================================================================
# This justfile is for development tasks only.
# For environment provisioning, use the menv CLI: menv create macbook
# ==============================================================================

set dotenv-load := true

# ==============================================================================
# Variables
# ==============================================================================

repo_root := `pwd`

# ==============================================================================
# Main Recipes
# ==============================================================================

default: help

# Display help with all available recipes
help:
    @echo "Usage: just [recipe]"
    @echo ""
    @echo "Development tasks for menv CLI:"
    @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# ==============================================================================
# CODE QUALITY
# ==============================================================================

# Format code with ruff
fix:
    @echo "Formatting code..."
    @just --fmt --unstable
    @uv run ruff format src/ tests/
    @uv run ruff check src/ tests/ --fix
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        echo "Found shell files to format"; \
        shfmt -w -d $files; \
    fi
    @uv run ansible-lint src/menv/ansible/ --fix || true

# Lint code with ruff, mypy, shellcheck, and ansible-lint
check: fix
    @echo "Linting code..."
    @just --fmt --check --unstable
    @uv run ruff format --check src/ tests/
    @uv run ruff check src/ tests/
    @uv run mypy src/ tests/
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        echo "Checking shell files"; \
        shellcheck $files; \
    fi
    @uv run ansible-lint src/menv/ansible/

# ==============================================================================
# TESTING
# ==============================================================================

# Run all tests
test: unit-test intg-test

# Run unit tests only
unit-test:
    @echo "🧪 Running unit tests..."
    @uv run pytest tests/unit/

# Run integration tests only
intg-test:
    @echo "🔗 Running integration tests..."
    @uv run pytest tests/intg/

# ==============================================================================
# RUN
# ==============================================================================

# Run menv CLI in development mode
run *args:
    @uv run menv {{ args }}

# ==============================================================================
# CLEANUP
# ==============================================================================

# Remove __pycache__, .venv and other temporary files
clean:
    @echo "🧹 Cleaning up project..."
    @find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    @rm -rf .venv
    @rm -rf .pytest_cache
    @rm -rf .ruff_cache
    @rm -rf dist
    @rm -rf *.egg-info
    @echo "✅ Cleanup completed"

# ==============================================================================
# Hidden Recipes
# ==============================================================================

# @hidden
_find_shell_files:
    @find . -type f \( -name "*.sh" -o -name "*.bash" \) | \
    grep -v "\.git" | \
    grep -v "\.uv-cache" | \
    grep -v "\.venv"
