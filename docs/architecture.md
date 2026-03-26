# Architecture

## Canonical Model

- Profile: A machine hardware configuration target (e.g., Macbook, MacMini, Common) mapped to an Ansible execution context.
- Identity: Personal or work VCS configuration elements (name, email) applied to Git and Jujutsu.
- Tag: An individual provisioning task or group of tasks resolved into an execution plan.
- Backup Target: A defined system state or application configuration (e.g., macOS defaults, VSCode extensions) preserved by the tool.

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
│   ├── vcs_identity.rs     # VCS identity configuration model
│   ├── backup_target.rs    # Backup target resolution and metadata
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
└── mev-internal/          # Internal command implementations (vcs)

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

## Design Rules

### Path Resolution
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path`, `local_config_root` as Ansible extra vars
- `local_config_root` points to `~/.config/mev/roles` for externalized configs
- Roles handle fallback logic (profile-specific → common)

### Profile Design
- Common profile operates by default: most roles use `common` profile
- Profile-specific configs apply: `brew` role supports profile-specific configs (macbook/mac-mini)
- Roles store configs in `config/common/` (all roles) and `config/profiles/` (e.g., brew, llm)

### Config Deployment Strategy
Two-stage config deployment executes via:
1. Package → `~/.config/mev/roles/{role}/`: Copy via `mev config deploy` or auto-deploy on `mev make`
2. `~/.config/mev/roles/{role}/` → Local destinations: Symbolic links
