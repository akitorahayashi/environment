#!/bin/bash

# Basic Cargo Commands
alias cr="cargo"
alias cr-n="cargo new"
alias cr-i="cargo install"
alias cr-i-g="cargo install --git"

# Formatting
alias cr-f="cargo fmt"

# Building
alias cr-b="cargo build"
alias cr-b-r="cargo build --release"

# Running
cr-r() {
	if [ $# -eq 0 ]; then
		cargo run
	else
		cargo run -- "$@"
	fi
}

# Setup
alias cr-setup="cargo fetch --locked || echo '(fetch skipped: lockfile not frozen)'"

# Linting
alias cr-chk="cargo check; cargo fmt --check; cargo clippy --all-targets --all-features -- -D warnings"

# Testing
alias cr-t="RUST_TEST_THREADS=1 cargo test --all-targets --all-features"

# Cleanup
alias cr-cln="rm -rf target coverage dist"
