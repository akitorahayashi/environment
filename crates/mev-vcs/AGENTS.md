# mev-vcs Development Overview

## Project Summary
`mev-vcs` is the latency-sensitive library crate for `mev` version-control commands.
It exposes the `git` and `gh` tool boundaries invoked by `mev internal ...`
through the Rust CLI boundary. The crate owns command procedures and exposes
plain value-and-function APIs; clap parsing lives in `mev`.

## Architectural Highlights
- Sliced by external tool boundary: `git/` (git CLI) and `gh/` (gh CLI)
- `error.rs` and `process.rs` are the shared kernel reused by both slices
- `git/client.rs` and `gh/client.rs` own external command execution
- `git/repo_ref.rs` owns repository reference normalization and resolution, consumed by `gh`
- `git/submodule.rs` and `gh/labels.rs` own command procedures
- `gh/labels.json` stores the bundled label catalog
- Dependency direction is one-way: `gh → git → {error, process}`
- Consumed as a dependency by the `mev` CLI internal subcommand dispatch
