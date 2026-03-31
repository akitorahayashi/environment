# ==============================================================================
# justfile for mev development
# ==============================================================================
# Rust-first CLI for macOS development environment provisioning.
# Python is retained only for Ansible tooling in development workflows.
# ==============================================================================

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set dotenv-load := true

mod internal "crates/mev-internal/justfile"

# Show available recipes
default: help

# Show available recipes
help:
    @echo "Usage: just [recipe]"
    @echo ""
    @echo "Development tasks for mev CLI:"
    @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# ==============================================================================
# Environment Setup
# ==============================================================================

# Initialize project: install dependencies
setup:
    @echo "🪄 Installing tools with mise..."
    @mise trust
    @mise install --locked
    @echo "🐚 Installing shell tools with Homebrew..."
    brew install shellcheck shfmt
    @echo "🐍 Installing ansible-lint dependencies with uv..."
    @uv sync

# ==============================================================================
# Lint & Format
# ==============================================================================

# Format code
fix:
    cargo fmt
    just internal::fix
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        shfmt -w -d $files; \
    fi
    uv run ansible-lint src/assets/ansible/ --fix
    just --fmt --unstable

# Verify formatting, lint, and compilation
check:
    cargo fmt --check
    cargo clippy --all-targets --all-features -- -D warnings
    just internal::check
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        shellcheck $files; \
    fi
    uv run ansible-lint src/assets/ansible/
    just --fmt --check --unstable

# ==============================================================================
# Testing
# ==============================================================================

# Run all tests
test:
    cargo test --all-targets --all-features
    just internal::test

# Generate code coverage report
coverage:
    rm -rf target/tarpaulin coverage
    mise exec -- cargo tarpaulin \
        --engine llvm \
        --target-dir target/tarpaulin \
        --packages mev \
        --exclude-files 'reference/*' \
        --out Stdout \
        --out Html \
        --output-dir coverage \
        --all-features \
        --fail-under 40

# ==============================================================================
# Build Tasks
# ==============================================================================

# Compile the project
build:
    cargo build

# Compile the project for release
build-release:
    cargo build --release

# Compile release binary for darwin-aarch64 distribution
build-release-darwin-aarch64:
    cargo build --release --locked --target aarch64-apple-darwin

# ==============================================================================
# Execution
# ==============================================================================

# Run the project
run *args:
    @cargo run -- {{ args }}

# ==============================================================================
# Cleanup
# ==============================================================================

# Clean up project artifacts
clean:
    @echo "Cleaning up project..."
    @cargo clean
    @find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    @rm -rf .pytest_cache
    @echo "Cleanup completed"

# @hidden
_find_shell_files:
    @find . -type f \( -name "*.sh" -o -name "*.bash" \) | \
    grep -v "\.git" | \
    grep -v "^./reference/" | \
    grep -v "\.uv-cache" | \
    grep -v "\.venv" | \
    grep -v "\.jlo"
