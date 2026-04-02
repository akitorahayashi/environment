# Architecture

## Canonical Model

- Profile: A hardware configuration target (e.g., Macbook, MacMini, Global) mapped to an Ansible execution context.
- Identity: Personal or work Git configuration elements (name, email) applied to Git.
- Tag: An individual provisioning task or group of tasks resolved into an execution plan.
- Backup Component: A defined system state or application configuration (e.g., macOS defaults, VSCode extensions) preserved by the tool.

## Layers

| Layer | Path | Responsibility |
|---|---|---|
| Application | `src/app/` | CLI boundary, command orchestration, dependency wiring |
| Domain | `src/domain/` | Pure rules, command invariants, execution planning, interfaces |
| Ports | `src/domain/ports/` | Interface boundaries required by domain/application |
| Adapters | `src/adapters/` | Process execution, file I/O, catalog loading, runtime asset materialization |
| Internal dep | `crates/mev-internal/` | Internal command domain implementations reused by mev |
| Source assets | `src/assets/` | Source-of-truth Ansible playbooks and roles |
| Release assets | `GitHub Releases` | `mev-darwin-aarch64` binary distribution |

## Package Structure

```text
src/
├── main.rs               # Binary entry point
├── lib.rs                 # Library root
├── app/
│   ├── cli/               # clap argument contracts (1 file per command)
│   │   └── mod.rs         # Single owner of clap parser and command dispatch
│   ├── commands/           # Orchestration units per command domain
│   ├── container.rs        # Dependency wiring (ports → adapters)
│   └── api.rs              # Stable library entrypoints
├── domain/
│   ├── error.rs            # Typed domain errors
│   ├── ports/              # Trait interfaces
│   ├── profile.rs          # Profile identifiers and mapping
│   ├── tag.rs              # Tag resolution from catalogs
│   ├── identity.rs         # Git identity configuration model
│   ├── backup_component.rs # Backup component resolution and metadata
│   └── execution_plan.rs   # Deterministic ansible plan construction
├── adapters/
│   ├── ansible/            # Playbook execution, locator, runtime asset materialization
│   ├── fs.rs               # Filesystem adapter
│   ├── git.rs              # Git configuration adapter
│   ├── identity_store.rs   # Identity persistence and path resolution
│   ├── macos_defaults.rs   # macOS defaults adapter
│   ├── version_source.rs   # Update execution source
│   └── vscode.rs           # External tool adapter
├── assets/
│   └── ansible/            # Source-of-truth ansible assets embedded into binary
└── testing/                # In-process test doubles

crates/
└── mev-internal/          # Internal command implementations (git, gh)

tests/
├── harness/                # Shared fixtures (TestContext)
├── cli.rs + cli/           # CLI behavior contracts
├── library.rs + library/   # Public API contracts
├── adapters.rs + adapters/ # Adapter behavior contracts
├── runtime.rs + runtime/   # Binary invocation contracts
└── security.rs + security/ # Input validation contracts
```

## Architecture Principles

### Directory Naming
- Ambiguous names such as `core/`, `utils/`, `helpers/` are forbidden
- Every file belongs to a clear, specific category

### Adapter Module Topology
- `src/adapters/ansible/` owns multiple components and preserves internal module separation
- Other adapters live as single files directly under `src/adapters/` (`fs.rs`, `git.rs`, `identity_store.rs`, `macos_defaults.rs`, `version_source.rs`, `vscode.rs`)

## Design Rules

### Path Resolution
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path`, `local_config_root` as Ansible extra vars
- `local_config_root` points to `~/.config/mev/roles` for externalized configs
- Roles handle fallback logic (profile-specific → global)

### Profile Design
- Global profile operates by default: most roles use `global` profile
- Profile-specific configs apply: `brew` role supports profile-specific configs (macbook/mac-mini)
- Roles store configs in `config/global/` (all roles) and `config/profiles/` (e.g., brew, llm)

### Config Deployment Strategy
Two-stage config deployment executes via:
1. Package → `~/.config/mev/roles/{role}/`: Copy via `mev config deploy` or auto-deploy on `mev make`
2. `~/.config/mev/roles/{role}/` → Local destinations: Symbolic links
