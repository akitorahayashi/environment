# menv-internal Development Overview

## Project Summary
`menv-internal` is the latency-sensitive runtime binary for `menv` internal commands.
It provides the `aider`, `shell`, `ssh`, and `vcs` command domains invoked by `menv internal ...`
through the Python dispatch boundary.

## Tech Stack
- Language: Rust
- CLI Parsing: clap
- Development Dependencies: assert_cmd, predicates

## Coding Standards
- Formatter: rustfmt (max width 100, edition 2024)
- Linter: clippy with -D warnings (all warnings are errors)

## Naming Conventions
- Structs and Enums: PascalCase
- Functions and Variables: snake_case
- Modules: snake_case

## Verify Commands
- Format: cargo fmt --check
- Lint: cargo clippy --all-targets --all-features -- -D warnings
- Test: cargo test --all-targets --all-features

## Architectural Highlights
- Single binary with four subcommand domains: aider, shell, ssh, vcs
- `app/cli/mod.rs` owns the clap parser and dispatch
- Each domain is a sibling module in `app/cli/`
- Invoked by the Python `menv.commands.internal.dispatch` module
