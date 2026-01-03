# menv - macOS Environment Setup Project

## Overview

pipx-installable CLI for macOS dev environment setup using bundled Ansible playbooks.

## CLI Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `menv create <profile>` | `cr` | Create complete environment (macbook/mbk, mac-mini/mmn); use `-v` for verbose |
| `menv make <tag> [profile]` | `mk` | Run individual task (default: common); profile only needed for brew-deps/brew-cask |
| `menv list` | `ls` | List available tags |
| `menv backup <target>` | `bk` | Backup system/VS Code |
| `menv config set` | `cf set` | Set VCS identities interactively |
| `menv config show` | `cf show` | Show current VCS identity configuration |
| `menv config create [role]` | `cf cr [role]` | Deploy role configs to ~/.config/menv/; use `-o` for overlay |
| `menv switch <profile>` | `sw` | Switch VCS identity (personal/p, work/w) |
| `menv update` | `u` | Self-update via pipx |

## Package Structure

```text
src/menv/
├── main.py           # Typer CLI entry point
├── context.py        # AppContext (DI container)
├── commands/         # CLI commands (1 command per file)
├── models/           # Data models (1 file per domain)
├── services/         # Service classes (1 class per file)
├── protocols/        # Protocol definitions (1 per service)
└── ansible/          # Bundled Ansible playbooks and roles

tests/
├── unit/             # Unit tests (mocks, no external processes)
│   ├── commands/     # CLI command tests
│   └── services/     # Service tests
├── intg/             # Integration tests (subprocess, real scripts)
│   └── roles/        # Ansible role script tests
├── mocks/            # Mock implementations (1 class per file, Protocol-compliant)
└── conftest.py       # Shared fixtures
```

## Architecture Principles

### Directory Naming
- **No ambiguous names**: `core/`, `utils/`, `helpers/` are forbidden
- Every file must belong to a clear, specific category

### Models (`models/`)
- **1 file per domain** (group related models)
- Pure data structures (dataclass, TypedDict)
- No business logic

### Protocols (`protocols/`)
- Define interface for each service
- **Naming**: `XxxProtocol` suffix (e.g., `ConfigStorageProtocol`)
- Both real implementations and mocks must satisfy the Protocol

### Services (`services/`)
- **1 class per file**
- Each service must have a corresponding Protocol in `protocols/`
- **Naming**: Plain name without suffix (e.g., `ConfigStorage`)
- Example: `services/config_storage.py` (ConfigStorage) ↔ `protocols/config_storage.py` (ConfigStorageProtocol)

### Mocks (`tests/mocks/`)
- **1 class per file** (mirror service structure)
- Must implement corresponding Protocol
- Never put implementations in `__init__.py`

## Design Rules

### Path Resolution
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path`, `local_config_root` as Ansible extra vars
- `local_config_root` points to `~/.config/menv/roles` for externalized configs
- Roles handle fallback logic (profile-specific → common)
- Use `importlib.resources` for package path resolution

### Profile Design
- **Common profile by default**: Most roles use `common` profile (no explicit profile argument needed)
- **Profile-specific configs**: Only `brew` role has profile-specific configs (macbook/mac-mini)
  - `brew-deps` and `brew-cask` require profile specification (use aliases: mbk, mmn)
  - All other tasks default to `common` profile
- Roles store configs in `config/common/` (all roles) and `config/profiles/` (brew only)

### Config Deployment Strategy

**Two-stage config deployment:**
1. **Package → `~/.config/menv/roles/{role}/`**: Copy via `menv config create` or auto-deploy on `menv make`
2. **`~/.config/menv/roles/{role}/` → Local destinations**: Symbolic links (changes reflected immediately)

**Config externalization benefits:**
- Users can edit configs in `~/.config/menv/roles/` without reinstalling menv
- Changes to `.rust-version`, `tools.yml`, etc. take effect immediately
- No `pipx reinstall` required for config updates

**Usage in Ansible tasks:**
- Read configs from `{{ local_config_root }}/{role}/common/` or `{{ local_config_root }}/{role}/profiles/`
- Deployment to local destinations (`~/.zshrc`, `~/.gitconfig`, etc.): `ansible.builtin.file` with `state: link`
- Set `mode: "0644"` for config/text files, `mode: "0755"` for executable scripts

### Testing
- Run via `just test` (runs both unit-test and intg-test)
- `just unit-test`: Unit tests only (fast, mocks, no external processes)
- `just intg-test`: Integration tests only (subprocess, real scripts)
- Mocks must be Protocol-compliant for type safety
- Prefer DI over monkeypatch where possible

### Development
- `just run <args>`: Run menv in dev mode
- `just check`: Format and lint
