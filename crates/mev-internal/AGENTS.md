# mev-internal Development Overview

## Project Summary
`mev-internal` is the latency-sensitive library crate for `mev` internal commands.
It provides the `git` and `gh` command domains invoked by `mev internal ...`
through the Rust CLI boundary.

## Architectural Highlights
- Library crate with two command domains: git, gh
- `app/cli/mod.rs` owns the clap parser and dispatch
- `app/commands/` owns command orchestration
- `domain/` owns pure normalization and validation rules
- `adapters/` owns external command and environment access
- `src/assets/` stores bundled internal catalogs
- Consumed as a dependency by the `mev` CLI internal subcommand dispatch
