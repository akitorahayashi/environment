#!/bin/bash

# Basic Cargo Commands
alias cr="cargo"
alias cr-n="cargo new"
alias cr-i="cargo install"
alias cr-i-g="cargo install --git"

# Formatting
cr-f() {
	echo "Running: cargo fmt"
	cargo fmt
	echo "✔︎ Format completed"
}

# Building
cr-b() {
	echo "Running: cargo build"
	cargo build
	echo "✔︎ Build completed"
}

cr-b-r() {
	echo "Running: cargo build --release"
	cargo build --release
	echo "✔︎ Release build completed"
}

# Running
cr-r() {
	if [ $# -eq 0 ]; then
		echo "Running: cargo run"
		cargo run
		echo "✔︎ Run completed"
	else
		echo "Running: cargo run -- $*"
		cargo run -- "$@"
		echo "✔︎ Run with args completed"
	fi
}

# Setup
cr-setup() {
	echo "Running: cargo fetch --locked || echo '(fetch skipped: lockfile not frozen)'"
	cargo fetch --locked || echo '(fetch skipped: lockfile not frozen)'
	echo "✔︎ Setup completed"
}

# Linting
cr-l() {
	echo "Running: cargo check"
	cargo check
	echo "Running: cargo fmt --check"
	cargo fmt --check
	echo "Running: cargo clippy --all-targets --all-features -- -D warnings"
	cargo clippy --all-targets --all-features -- -D warnings
	echo "✔︎ Linting completed"
}

# Testing
cr-t() {
	echo "Running: RUST_TEST_THREADS=1 cargo test --all-targets --all-features"
	RUST_TEST_THREADS=1 cargo test --all-targets --all-features
	echo "✔︎ Tests completed"
}

# Cleanup
cr-cln() {
	echo "Running: rm -rf target coverage dist"
	rm -rf target coverage dist
	echo "✔︎ Cleanup completed"
}
