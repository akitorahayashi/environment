# menv - macOS Environment Setup Project

## Overview

pipx-installable CLI for macOS dev environment setup using bundled Ansible playbooks.

## CLI Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `menv introduce <profile>` | `itr` | Interactive setup guide (macbook/mbk, mac-mini/mmn); use `-nw` to skip waits |
| `menv make <tag> [profile]` | `mk` | Run individual task (default: common); profile only needed for brew-deps/brew-cask |
| `menv list` | `ls` | List available tags |
| `menv backup <target>` | `bk` | Backup system/VS Code |
| `menv config <action>` | `cf` | Manage VCS identities (set/show) |
| `menv switch <profile>` | `sw` | Switch VCS identity (personal/p, work/w) |
| `menv code` | - | Clone ~/menv (if needed) and open in VS Code |
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
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path` as Ansible extra vars
- Roles handle fallback logic (profile-specific → common)
- Use `importlib.resources` for package path resolution

### Profile Design
- **Common profile by default**: Most roles use `common` profile (no explicit profile argument needed)
- **Profile-specific configs**: Only `brew` role has profile-specific configs (macbook/mac-mini)
  - `brew-deps` and `brew-cask` require profile specification (use aliases: mbk, mmn)
  - All other tasks default to `common` profile
- Roles store configs in `config/common/` (all roles) and `config/profiles/` (brew only)

### Copy Enforcement
- Never create symlinks for user-facing config (pipx installs must remain stable across upgrades)
- Use `ansible.builtin.copy` with `force: true`
- Set `mode: "0644"` for config/text files, `mode: "0755"` for executable scripts
- For directories, copy contents by using trailing slashes on `src`/`dest` (e.g. `src: .../dir/`, `dest: .../dir/`)

### Testing
- Run via `just test` (runs both unit-test and intg-test)
- `just unit-test`: Unit tests only (fast, mocks, no external processes)
- `just intg-test`: Integration tests only (subprocess, real scripts)
- Mocks must be Protocol-compliant for type safety
- Prefer DI over monkeypatch where possible

### Development
- `just run <args>`: Run menv in dev mode
- `just check`: Format and lint
