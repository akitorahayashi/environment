# mev - macOS Environment Setup Project

## Overview

Rust-first CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable via `pipx` through a thin Python launcher that delegates to the prebuilt `mev` binary.

## Architecture

| Layer | Path | Responsibility |
|---|---|---|
| Application | `src/app/` | CLI boundary, command orchestration, dependency wiring |
| Domain | `src/domain/` | Pure rules, command invariants, execution planning, interfaces |
| Ports | `src/domain/ports/` | Interface boundaries required by domain/application |
| Adapters | `src/adapters/` | Process execution, file I/O, catalog loading, package asset resolution |
| Internal dep | `crates/mev-internal/` | Internal command domain implementations reused by mev |
| Python bootstrap | `dist/mev/` | Thin launcher delegating to bundled binary |
| Distribution assets | `dist/mev/` | Bundled binaries and ansible assets for dev and packaging |

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
│   ├── ansible_process/    # Binary resolution and process execution
│   ├── backup/             # System defaults and VSCode extension backup
│   ├── catalogs/           # Dynamic tag/role loading from playbook.yml
│   ├── local_config/       # JSON config persistence
│   ├── package_assets/     # Asset root resolution (dev + packaged)
│   ├── vcs/                # Git and Jujutsu identity configuration
│   └── version/            # Version information source
├── assets/                 # Embedded static resources
└── testing/                # In-process test doubles

crates/
└── mev-internal/          # Internal command implementations (aider, shell, ssh, vcs)

dist/
└── mev/
    ├── launcher.py         # Thin Python launcher for pipx entry
    ├── bin/                # Bundled Rust binaries
    └── ansible/            # Runtime ansible assets

tests/
├── harness/                # Shared fixtures (TestContext)
├── cli.rs + cli/           # CLI behavior contracts
├── library.rs + library/   # Public API contracts
├── adapters.rs + adapters/ # Adapter behavior contracts
├── runtime.rs + runtime/   # Binary invocation contracts
└── security.rs + security/ # Input validation contracts
```

## Python Surface

Python ownership is limited to `dist/mev/launcher.py`.
The launcher resolves packaged assets, sets `MEV_ANSIBLE_DIR`, and executes the bundled Rust binary.
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
- `just build-bundle`: Build release binary for pipx distribution
