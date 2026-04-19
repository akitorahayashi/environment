# mev - macOS Environment Setup Project

## Overview

Rust CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable as a standalone Rust binary via `install.sh`.
## Architecture

| Boundary | Path | Responsibility |
|---|---|---|
| CLI adapter | src/cli/ | clap parsing and command dispatch |
| Application orchestration | src/app/ | use-case flow orchestration and context composition |
| Provisioning owner | src/provisioning/ | provisioning model, contracts, ansible runtime, asset resolution |
| Identity owner | src/identity/ | identity model, storage contract, git config contract, integrations |
| Backup owner | src/backup/ | backup component model and backup integrations |
| Update owner | src/update/ | update contract and install script integration |
| Shared kernel | src/host_fs/ | reusable filesystem contract and std implementation |
| Shared kernel | src/error.rs | crate-wide typed errors |
| Assets | src/assets/ | Source-of-truth embedded static resources |
| Test support | src/test_support/ | In-process test doubles reused across owners |
| Internal dep | crates/mev-internal/ | Internal command domain implementations reused by mev |

## App structure

- `context.rs` wires owner contracts to concrete integrations.
- `provisioning/`, `identity/`, `backup/`, `update/`, and `internal/` contain use-case orchestration families.

## Owner structure

- Each owner module contains its own contracts and concrete implementations.
- Provisioning contracts are split by ownership (`catalog`, `runner`, `role_configs`) instead of a single mixed interface.

## Docs

For detailed work and architectural guidelines, agents use the following as their primary sources of truth:
- [Contributing](CONTRIBUTING.md): Workflow, coding standards, and procedural verification rules.
- [Docs](docs/): The central index for architectural decisions, system usage, and configuration specifications.

The CLI commands are detailed in [Docs Usage](docs/usage.md).

## Python Surface

Python ownership is limited to development tooling (`ansible-lint`) managed by `pyproject.toml`.
Runtime command ownership belongs to the Rust implementation.
