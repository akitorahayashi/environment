# mev - macOS Environment Setup Project

## Overview

Rust CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable as a standalone Rust binary via `install.sh`.
## Architecture

| Layer | Path | Responsibility |
|---|---|---|
| Application | src/app/ | CLI boundary, command orchestration, dependency wiring |
| Domain | src/domain/ | Pure rules, command invariants, execution planning, interfaces |
| Ports | src/domain/ports/ | Interface boundaries (traits) required by domain/application |
| Adapters | src/adapters/ | Process execution, file I/O, catalog loading, package asset resolution |
| Assets | src/assets/ | Source-of-truth embedded static resources |
| Testing | src/testing/ | In-process test doubles and builders |
| Internal dep | crates/mev-internal/ | Internal command domain implementations reused by mev |

## App structure

- `cli/` contains clap input contracts only.
- `commands/` contains orchestration units per command domain.
- `context.rs` wires ports to adapters without command logic duplication.
- `api.rs` exposes stable library entrypoints used by `main.rs`.

## Domain structure

- `error.rs` contains domain-level typed errors.
- `ports/` defines explicit interfaces consumed by application and domain.

## Docs

For detailed work and architectural guidelines, agents use the following as their primary sources of truth:
- [Contributing](CONTRIBUTING.md): Workflow, coding standards, and procedural verification rules.
- [Docs](docs/): The central index for architectural decisions, system usage, and configuration specifications.

The CLI commands are detailed in [Docs Usage](docs/usage.md).

## Python Surface

Python ownership is limited to development tooling (`ansible-lint`) managed by `pyproject.toml`.
Runtime command ownership belongs to the Rust implementation.
