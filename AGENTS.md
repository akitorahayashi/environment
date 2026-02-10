# menv - macOS Environment Setup Project

## Overview

pipx-installable CLI for macOS dev environment setup using bundled Ansible playbooks.

## CLI Commands

See [README.md](README.md) for the list of available commands and usage instructions.

## Package Structure

```text
src/menv/
├── main.py           # Typer CLI entry point
├── context.py        # AppContext (DI container)
├── commands/         # CLI commands (1 command per file)
│   └── internal/     # Hidden alias-backing commands (1 domain per file)
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

## Directory Specific Rules

Please refer to the `AGENTS.md` files in specific directories for detailed rules:

- [Internal Commands](src/menv/commands/internal/AGENTS.md)
- [Models](src/menv/models/AGENTS.md)
- [Protocols](src/menv/protocols/AGENTS.md)
- [Rust Role](src/menv/ansible/roles/rust/AGENTS.md)
- [Services](src/menv/services/AGENTS.md)
- [Mocks](tests/mocks/AGENTS.md)
- [Testing](tests/AGENTS.md)

## Architecture Principles

### Directory Naming
- **No ambiguous names**: `core/`, `utils/`, `helpers/` are forbidden
- Every file must belong to a clear, specific category

## Design Rules

### Path Resolution
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path`, `local_config_root` as Ansible extra vars
- `local_config_root` points to `~/.config/menv/roles` for externalized configs
- Roles handle fallback logic (profile-specific → common)
- Use `importlib.resources` for package path resolution

### Profile Design
- **Common profile by default**: Most roles use `common` profile (no explicit profile argument needed)
- **Profile-specific configs**: `brew` role supports profile-specific configs (macbook/mac-mini)
  - `brew-formulae` and `brew-cask` prioritize profile-specific Brewfiles but fallback to `common` if not found.
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

### Agent Skills SSOT (Single Source of Truth)

**Managed by:** `nodejs` role (coder task)

**Source location:** `~/.config/menv/roles/nodejs/common/coder/skills/{skill_name}/`

**Target consumers:**
- `~/.codex/skills/` (Codex CLI)
- `~/.claude/skills/` (Claude CLI)
- `~/.gemini/skills/` (Gemini CLI)
- `~/.config/google/antigravity/skills/` (Google Antigravity)

**Configuration:** Add tool names to `skills-targets.yml` to enable automatic skills deployment

**Example integration:**
- Google Antigravity added to `skills-targets.yml` → Skills automatically deployed by coder role
- Editor role creates parent directory `~/.config/google/antigravity` as prerequisite
- Coder role handles individual skill symlinks via standard SSOT mechanism

**Design principle:**
- Config sharing strategies vary by content type:
  - **Settings/Keybindings**: Fully shared via symlinks (editor role manages)
  - **Extensions**: Fully separated per tool (editor role manages)
  - **Agent Skills**: SSOT with reference sharing (nodejs/coder role manages)

### Development
- `just run <args>`: Run menv in dev mode
- `just check`: Format and lint
