# mev-internal Development Overview

## Project Summary
`mev-internal` is the latency-sensitive library crate for `mev` internal commands.
It provides the `git` and `gh` command domains invoked by `mev internal ...`
through the Rust CLI boundary.

## Tech Stack
- Language: Rust
- CLI Parsing: clap
- Development Dependencies: tempfile, serde_json

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
- Library crate with two command domains: git, gh
- `app/cli/mod.rs` owns the clap parser and dispatch
- `app/commands/` owns command orchestration
- `domain/` owns pure normalization and validation rules
- `adapters/` owns external command and environment access
- `src/assets/` stores bundled internal catalogs
- Consumed as a dependency by the `mev` CLI internal subcommand dispatch
