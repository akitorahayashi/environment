# ==============================================================================
# justfile for mev development
# ==============================================================================
# Rust-first CLI for macOS development environment provisioning.
# Python remains only as a minimal launcher surface for pipx command exposure.
# ==============================================================================

set shell := ["bash", "-eu", "-o", "pipefail", "-c"]
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
    @echo "Development tasks for mev CLI:"
    @just --list | tail -n +2 | awk '{printf "  \033[36m%-20s\033[0m %s\n", $1, substr($0, index($0, $2))}'

# ==============================================================================
# CODE QUALITY (Rust)
# ==============================================================================

# Format Rust code
fmt:
    cargo fmt

# Lint and check Rust code
check: fmt
    cargo check
    cargo fmt --check
    cargo clippy --all-targets --all-features -- -D warnings

# ==============================================================================
# CODE QUALITY (Python — legacy surface)
# ==============================================================================

# Format Python code
py-fix:
    @echo "Formatting Python code..."
    @just --fmt --unstable
    @uv run ruff format src/menv/ tests/
    @uv run ruff check src/menv/ tests/ --fix
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        echo "Found shell files to format"; \
        shfmt -w -d $files; \
    fi
    @uv run ansible-lint src/menv/ansible/ --fix || true

# Lint Python code
py-check: py-fix
    @echo "Linting Python code..."
    @just --fmt --check --unstable
    @uv run ruff format --check src/menv/ tests/
    @uv run ruff check src/menv/ tests/
    @uv run mypy src/menv/ tests/
    @files=$(just _find_shell_files); \
    if [ -n "$files" ]; then \
        echo "Checking shell files"; \
        shellcheck $files; \
    fi
    @uv run ansible-lint src/menv/ansible/

# ==============================================================================
# BUILD
# ==============================================================================

# Build mev binary
build:
    cargo build

# Build mev binary in release mode
build-release:
    cargo build --release

# Build menv-internal and place binary in bundled_binaries
build-internal:
    #!/usr/bin/env bash
    set -euo pipefail
    system="$(uname -s | tr '[:upper:]' '[:lower:]')"
    machine="$(uname -m | tr '[:upper:]' '[:lower:]')"
    [[ "$machine" == "arm64" ]] && machine="aarch64"
    platform="${system}-${machine}"
    dest_dir="{{ repo_root }}/src/menv/bundled_binaries/${platform}"
    mkdir -p "$dest_dir"
    target_dir="{{ repo_root }}/crates/menv-internal/target"
    cargo build --release --target-dir "$target_dir" --manifest-path "{{ repo_root }}/crates/menv-internal/Cargo.toml"
    cp "$target_dir/release/menv-internal" "$dest_dir/menv-internal"
    chmod +x "$dest_dir/menv-internal"
    echo "✅ Built menv-internal -> ${dest_dir}/menv-internal"

# Build mev binary and place in bundled_binaries for pipx distribution
build-bundle: build-release build-internal
    #!/usr/bin/env bash
    set -euo pipefail
    system="$(uname -s | tr '[:upper:]' '[:lower:]')"
    machine="$(uname -m | tr '[:upper:]' '[:lower:]')"
    [[ "$machine" == "arm64" ]] && machine="aarch64"
    platform="${system}-${machine}"
    dest_dir="{{ repo_root }}/src/menv/bundled_binaries/${platform}"
    mkdir -p "$dest_dir"
    cp "{{ repo_root }}/target/release/mev" "$dest_dir/mev"
    chmod +x "$dest_dir/mev"
    echo "✅ Built mev -> ${dest_dir}/mev"

# ==============================================================================
# TESTING
# ==============================================================================

# Run all Rust tests
test:
    cargo test --all-targets --all-features

# Run Python unit tests only
py-unit-test:
    @echo "Running Python unit tests..."
    @uv run pytest tests/unit/

# Run Python integration tests only
py-intg-test:
    @echo "Running Python integration tests..."
    @uv run pytest tests/intg/

# Run all Python tests
py-test: py-unit-test py-intg-test

# ==============================================================================
# RUN
# ==============================================================================

# Run mev CLI in development mode
run *args:
    @cargo run -- {{ args }}

# Run legacy Python menv CLI
py-run *args:
    @uv run menv {{ args }}

# ==============================================================================
# CLEANUP
# ==============================================================================

# Remove build artifacts and temporary files
clean:
    @echo "Cleaning up project..."
    @cargo clean
    @find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
    @rm -rf .pytest_cache
    @rm -rf .ruff_cache
    @rm -rf dist
    @rm -rf *.egg-info
    @echo "✅ Cleanup completed"

# ==============================================================================
# COVERAGE
# ==============================================================================

coverage:
    rm -rf target/tarpaulin coverage
    env -u RUSTC_WRAPPER -u SCCACHE_IGNORE_SERVER_IO_ERROR -u SCCACHE_ERROR_LOG mise exec -- cargo tarpaulin --engine llvm --out Xml --output-dir coverage --all-features --fail-under 40

# ==============================================================================
# Hidden Recipes
# ==============================================================================

# @hidden
_find_shell_files:
    @find . -type f \( -name "*.sh" -o -name "*.bash" \) | \
    grep -v "\.git" | \
    grep -v "\.uv-cache" | \
    grep -v "\.venv" | \
    grep -v "\.jlo"
