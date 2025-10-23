#!/bin/bash
# cargo.sh - convenient cargo aliases and helper functions for zsh
# Provides small wrappers for common workflows (installing components,
# building, running, formatting, linting, testing, and cleaning).

alias cr="cargo"
alias cr-n="cargo new"
alias cr-i="cargo install"
alias cr-i-g="cargo install --git"
alias cr-f="cargo fmt"
alias cr-fmt="cargo fmt"
alias cr-b="cargo build"
alias cr-build-release="cargo build --release"

# Install rust components and warm caches (matches justfile `setup`)
cr-setup() {
	echo "🛠 Installing rustfmt and clippy..."
	rustup component add rustfmt clippy
	echo "🚚 Fetching dependencies..."
	cargo fetch --locked || echo "(fetch skipped: lockfile not frozen)"
}

# Run the project with arbitrary arguments: cr-run arg1 arg2 ...
cr-run() {
	if [ $# -eq 0 ]; then
		echo "🚀 Running cargo run (no args)"
		cargo run
	else
		echo "🚀 Running cargo run -- $*"
		cargo run -- "$@"
	fi
}

# Formatting helpers
cr-format() { cargo fmt "$@"; }

# Lint: format check then clippy (matches justfile `lint`)
cr-lint() {
	echo "🔍 Ensuring formatting is clean..."
	cargo fmt --check
	echo "🛡 Running clippy..."
	cargo clippy --all-targets --all-features -- -D warnings
}

# Run tests (matches justfile `test`)
cr-test() {
	echo "🚀 Running all unit and integration tests..."
	RUST_TEST_THREADS=1 cargo test --all-targets --all-features "$@"
}

# Run E2E tests (matches justfile `e2e-test`)
cr-e2e-test() {
	echo "🚀 Running end-to-end smoke tests..."
	RUST_TEST_THREADS=1 cargo test --test cli_flow -- --ignored "$@"
}

# Cleanup artifacts (matches justfile `clean`)
cr-clean() {
	echo "🧽 Cleaning build artifacts and caches..."
	rm -rf target .tmp coverage dist
	echo "✅ Cleanup completed"
}
