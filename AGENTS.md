# mev - macOS Environment Setup Project

## Overview

Rust CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable as a standalone Rust binary via `install.sh`.

## Platform Assumption

The project targets macOS hosts.
Cross-platform behavior is not assumed unless an owning file or role declares it explicitly.

## Architecture

| Boundary | Path | Responsibility |
|---|---|---|
| CLI adapter | src/cli/ | clap parsing and command dispatch |
| Application orchestration | src/app/ | use-case flow orchestration and context composition |
| Provisioning owner | src/provisioning/ | provisioning model, contracts, ansible runtime, asset resolution |
| Identity owner | src/identity/ | identity model, storage contract, git config contract, integrations |
| Backup owner | src/backup/ | backup component model and backup integrations |
| Update owner | src/update/ | update contract and install script integration |
| Coder owner | src/coder/ | AGENTS.md section and skills catalog, selection manifest, intermediate-entity build |
| Shared kernel | src/host_fs/ | reusable filesystem contract and std implementation |
| Shared kernel | src/error.rs | crate-wide typed errors |
| Assets | src/assets/ | Source-of-truth embedded static resources |
| Test support | src/test_support/ | In-process test doubles reused across owners |
| Internal dep | crates/mev-vcs/ | git/gh tool-boundary command implementations reused by mev |

## App structure

- `src/app/context.rs` wires owner contracts to concrete integrations.
- `src/app/provisioning/`, `src/app/identity/`, `src/app/backup/`, `src/app/update/`, and `src/app/coder/` contain use-case orchestration families.
- `src/cli/internal.rs` owns the `mev internal ...` clap shape and dispatches directly to `mev-vcs` without an `src/app/` orchestration layer.

## Owner structure

- Each owner module (e.g., `src/provisioning/`, `src/identity/`) contains its own contracts and concrete implementations.
- Provisioning contracts are split by ownership (`catalog`, `runner`, `role_configs`) instead of a single mixed interface.
- The coder owner shares a catalog and selection manifest across AGENTS.md sections and skills, splitting only the intermediate-entity build (`agents_build`, `skills_build`).

## Docs

For detailed work and architectural guidelines, agents use the following as their primary sources of truth:
- [Contributing](CONTRIBUTING.md): Workflow, coding standards, and procedural verification rules.
- [Docs](docs/): The central index for architectural decisions, system usage, and configuration specifications.

The CLI commands are detailed in [Docs Usage](docs/usage.md).

## Python Surface

Python ownership is limited to development tooling managed by `pyproject.toml`.
Runtime command ownership belongs to the Rust implementation.

## Generated Ansible Setup Workflows

- `.github/ansible-setup-targets.yml` is the source of truth for Ansible setup CI targets.
- `.github/scripts/generate_ansible_setup_workflows.py` generates `.github/workflows/setup-*.yml` and `.github/workflows/verify-ansible-setup.yml`.
- Generated setup workflows are derived artifacts and are excluded from routine inspection and direct editing.
- `just generate-ansible-setups` updates generated workflows.
- `just verify-generated-ansible-setups` verifies generated workflows match their source.
