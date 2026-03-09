# mev - macOS Environment Setup Project

## Overview

Rust-first CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable as a standalone Rust binary via `install.sh`.

## Architecture

| Layer | Path | Responsibility |
|---|---|---|
| Application | `src/app/` | CLI boundary, command orchestration, dependency wiring |
| Domain | `src/domain/` | Pure rules, command invariants, execution planning, interfaces |
| Ports | `src/domain/ports/` | Interface boundaries required by domain/application |
| Adapters | `src/adapters/` | Process execution, file I/O, catalog loading, runtime asset materialization |
| Internal dep | `crates/mev-internal/` | Internal command domain implementations reused by mev |
| Source assets | `src/assets/` | Source-of-truth Ansible playbooks and roles |
| Release assets | `GitHub Releases` | `mev-darwin-aarch64` binary distribution |

## CLI Commands

See [README.md](README.md) for the list of available commands and usage instructions.

## Package Structure

```text
src/
├── main.rs               # Binary entry point
├── lib.rs                 # Library root
├── app/
│   ├── cli/               # clap argument contracts (1 file per command)
│   │   └── mod.rs         # Single owner of clap parser and command dispatch
│   ├── commands/           # Orchestration units per command domain
│   ├── context.rs          # Dependency wiring (ports → adapters)
│   └── api.rs              # Stable library entrypoints
├── domain/
│   ├── error.rs            # Typed domain errors
│   ├── ports/              # Trait interfaces
│   ├── profile.rs          # Profile identifiers and mapping
│   ├── tag.rs              # Tag resolution from catalogs
│   ├── config.rs           # VCS identity configuration model
│   └── execution_plan.rs   # Deterministic ansible plan construction
├── adapters/
│   ├── ansible/            # Playbook execution, locator, runtime asset materialization
│   ├── identity_store/     # Identity persistence and path resolution
│   ├── macos_defaults/     # macOS defaults adapter
│   ├── version_source/     # Update execution source
│   ├── git/, jj/, vscode/  # External tool adapters
│   └── fs/                 # Filesystem adapter
├── assets/
│   └── ansible/            # Source-of-truth ansible assets embedded into binary
└── testing/                # In-process test doubles

crates/
└── mev-internal/          # Internal command implementations (aider, shell, ssh, vcs)

tests/
├── harness/                # Shared fixtures (TestContext)
├── cli.rs + cli/           # CLI behavior contracts
├── library.rs + library/   # Public API contracts
├── adapters.rs + adapters/ # Adapter behavior contracts
├── runtime.rs + runtime/   # Binary invocation contracts
└── security.rs + security/ # Input validation contracts
```

## Python Surface

Python ownership is limited to development tooling (`ansible-lint`) managed by `pyproject.toml`.
Runtime command ownership belongs to the Rust implementation.

## Architecture Principles

### Directory Naming
- No ambiguous names: `core/`, `utils/`, `helpers/` are forbidden
- Every file must belong to a clear, specific category

## Design Rules

### Path Resolution
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path`, `local_config_root` as Ansible extra vars
- `local_config_root` points to `~/.config/mev/roles` for externalized configs
- Roles handle fallback logic (profile-specific → common)

### Profile Design
- Common profile by default: most roles use `common` profile
- Profile-specific configs: `brew` role supports profile-specific configs (macbook/mac-mini)
- Roles store configs in `config/common/` (all roles) and `config/profiles/` (brew only)

### Config Deployment Strategy
Two-stage config deployment:
1. Package → `~/.config/mev/roles/{role}/`: Copy via `mev config create` or auto-deploy on `mev make`
2. `~/.config/mev/roles/{role}/` → Local destinations: Symbolic links

### Development
- `just run <args>`: Run mev in dev mode
- `just check`: Format and lint
- `just test`: Run all Rust tests
- `v*` tag push: `.github/workflows/release.yml` publishes `mev-darwin-aarch64` to GitHub Releases
