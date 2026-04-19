# Architecture

## Canonical Model

- Profile: A hardware configuration target (e.g., Macbook, MacMini, Global) mapped to a provisioning execution context.
- Identity: Personal or work Git configuration elements (name, email) applied to Git.
- Tag: An individual provisioning task or group of tasks resolved into an execution plan.
- Backup Component: A defined system state or application configuration (e.g., macOS defaults, VSCode extensions) preserved by the tool.

## Ownership Boundaries

| Boundary | Path | Responsibility |
|---|---|---|
| Interface adapter | `src/cli/` | clap parsing, command dispatch, process exit shaping |
| Application orchestration | `src/app/` | Use-case flow coordination and dependency composition |
| Provisioning owner | `src/provisioning/` | Tag catalog, plan construction, playbook execution, role config deployment policy, provisioning assets resolution |
| Identity owner | `src/identity/` | Identity model, identity persistence contract, Git identity contract and integrations |
| Backup owner | `src/backup/` | Backup component resolution, system defaults backup, VSCode backup, backup integrations |
| Update owner | `src/update/` | Version source contract and install script integration |
| Shared kernel | `src/host_fs/` | Reusable host filesystem contract and std implementation |
| Shared kernel | `src/error.rs` | Typed application error model |
| Static source content | `src/assets/` | Source-of-truth Ansible playbooks and roles |
| Test support | `src/test_support/` | Crate-wide in-process test doubles |
| Internal dep | `crates/mev-internal/` | Internal command implementations reused by `mev` |
| Release assets | `GitHub Releases` | `mev-darwin-aarch64` binary distribution |

## Package Structure

```text
src/
├── main.rs                # Binary entry point
├── lib.rs                 # Library root and public entrypoints
├── error.rs               # Shared typed errors
├── cli/                   # CLI boundary
│   ├── mod.rs             # clap parser and top-level dispatch
│   ├── create.rs
│   ├── make.rs
│   ├── list.rs
│   ├── config.rs
│   ├── identity.rs
│   ├── switch.rs
│   ├── update.rs
│   ├── backup.rs
│   └── internal.rs
├── app/
│   ├── context.rs          # Composition root for use-case contexts
│   ├── provisioning/       # Provisioning use-case orchestration
│   ├── identity/           # Identity use-case orchestration
│   ├── backup/             # Backup use-case orchestration
│   ├── update/             # Update use-case orchestration
│   └── internal/           # Internal command orchestration
├── provisioning/
│   ├── profile.rs
│   ├── tag_selection.rs
│   ├── execution_plan.rs
│   ├── catalog.rs
│   ├── runner.rs
│   ├── role_configs.rs
│   ├── ansible_runtime.rs
│   └── assets/
│       ├── locator.rs
│       └── embedded.rs
├── identity/
│   ├── identity.rs
│   ├── store.rs
│   ├── git_config.rs
│   ├── file_store.rs
│   └── git_cli.rs
├── backup/
│   ├── component.rs
│   ├── system.rs
│   ├── vscode.rs
│   ├── macos_defaults_port.rs
│   ├── macos_defaults_cli.rs
│   ├── vscode_port.rs
│   └── vscode_cli.rs
├── update/
│   ├── version_source.rs
│   └── install_script.rs
├── host_fs/
│   ├── fs.rs
│   └── std_fs.rs
├── assets/
│   └── ansible/            # Source-of-truth ansible assets embedded into binary
└── test_support/
	├── provisioning.rs
	└── host_fs.rs

crates/
└── mev-internal/           # Internal command implementations (git, gh)

tests/
├── harness/                # Shared fixtures (TestContext)
├── cli.rs + cli/           # CLI behavior contracts
├── library.rs + library/   # Public API contracts
├── adapters.rs + adapters/ # Adapter behavior contracts
├── runtime.rs + runtime/   # Binary invocation contracts
└── security.rs + security/ # Input validation contracts
```

## Application Structure

- `src/cli/` is the only CLI parsing and dispatch boundary.
- `src/app/` orchestrates use cases grouped by family (`provisioning`, `identity`, `backup`, `update`, `internal`).
- `src/app/context.rs` is the composition root for runtime dependencies.
- Public library entrypoints are exposed from `src/lib.rs` and delegate into app orchestration.

## Provisioning Contract Model

- `ProvisioningCatalog` owns read-only tag/group/role catalog access.
- `ProvisioningRunner` owns playbook execution.
- `RoleConfigLocator` owns role config directory discovery.
- `AnsibleRuntime` is the concrete implementation of these provisioning contracts.
- Provisioning asset lookup and embedded materialization are owned under `src/provisioning/assets/`.

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
