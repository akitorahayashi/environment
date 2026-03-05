# ==============================================================================
# justfile for mev development
# ==============================================================================
# Rust-first CLI for macOS development environment provisioning.
# Python is retained only for the minimal pipx launcher surface.
# ==============================================================================

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
set dotenv-load := true

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

# Initialize project: install dependencies, configure hooks
setup:
    @echo "🪄 Installing tools with mise..."
    @mise trust
    @mise install --locked
    @echo "🐍 Installing python dependencies with uv..."
    @uv sync
    @echo "🪝 Configuring git hooks..."
    chmod +x .githooks/pre-commit
    git config core.hooksPath .githooks

# ==============================================================================
# Lint & Format
# ==============================================================================

# Format code
fix:
    cargo fmt
    cargo fmt --manifest-path crates/mev-internal/Cargo.toml
    uv run ruff format dist/mev/
    uv run ruff check dist/mev/ --fix
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        shfmt -w -d $files; \
    fi
    uv run ansible-lint dist/mev/ansible/ --fix
    just --fmt --unstable

# Verify formatting, lint, and compilation
check:
    cargo fmt --check
    cargo fmt --manifest-path crates/mev-internal/Cargo.toml --check
    cargo clippy --all-targets --all-features -- -D warnings
    cargo clippy --manifest-path crates/mev-internal/Cargo.toml --all-targets --all-features -- -D warnings
    uv run ruff format --check dist/mev/
    uv run ruff check dist/mev/
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        shellcheck $files; \
    fi
    uv run ansible-lint dist/mev/ansible/
    just --fmt --check --unstable

# ==============================================================================
# Testing
# ==============================================================================

# Run all tests
test:
    cargo test --all-targets --all-features
    cargo test --manifest-path crates/mev-internal/Cargo.toml --all-targets --all-features

# Generate code coverage report
coverage:
    rm -rf target/tarpaulin coverage
    env -u RUSTC_WRAPPER -u SCCACHE_IGNORE_SERVER_IO_ERROR -u SCCACHE_ERROR_LOG mise exec -- cargo tarpaulin --engine llvm --out Xml --output-dir coverage --all-features --fail-under 40

# ==============================================================================
# Build Tasks
# ==============================================================================

# Compile the project
build:
    cargo build

# Compile the project for release
build-release:
    cargo build --release

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
    @rm -rf .ruff_cache
    @rm -f dist/*.whl dist/*.tar.gz
    @rm -rf *.egg-info
    @echo "Cleanup completed"

# @hidden
_find_shell_files:
    @find . -type f \( -name "*.sh" -o -name "*.bash" \) | \
    grep -v "\.git" | \
    grep -v "\.uv-cache" | \
    grep -v "\.venv" | \
    grep -v "\.jlo"
