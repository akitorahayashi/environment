# menv - macOS Environment Setup Project

## Overview

pipx-installable CLI for macOS dev environment setup using bundled Ansible playbooks.

## CLI Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `menv create <profile>` | `cr` | Full setup (macbook/mbk, mac-mini/mmn) |
| `menv make <tag> [profile]` | `mk` | Run individual task (default: common) |
| `menv list` | `ls` | List available tags |
| `menv backup <target>` | `bk` | Backup system/vscode |
| `menv config <action>` | `cf` | Manage VCS identities (set/show) |
| `menv switch <profile>` | `sw` | Switch VCS identity (personal/p, work/w) |
| `menv code` | - | Open menv source code in VS Code |
| `menv update` | `u` | Self-update via pipx |

## Package Structure

```
src/menv/
├── main.py           # Typer CLI entry point
├── commands/
│   ├── backup.py     # backup/bk command
│   ├── config.py     # config/cf command
│   ├── create.py     # create/cr command (full profile setup)
│   ├── make.py       # make/mk command (individual tasks)
│   ├── switch.py     # switch/sw command
│   └── update.py     # update/u command
├── core/
│   ├── config.py     # Configuration management (~/.config/menv/config.toml)
│   ├── paths.py      # importlib.resources path resolution
│   ├── runner.py     # Ansible subprocess execution
│   └── version.py    # Version checking via GitHub API
└── ansible/          # Bundled Ansible playbooks and roles
    ├── playbook.yml
    └── roles/
```

## Design Rules

### Path Resolution
- CLI passes `profile`, `config_dir_abs_path`, `repo_root_path` as Ansible extra vars
- Roles handle fallback logic (profile-specific → common)
- Use `importlib.resources` for package path resolution

### Symlink Enforcement
- Always use `force: true` when creating symlinks
- Overwrite existing files/links unconditionally

### Testing
- Run via `just test` (executes `uv run pytest tests/`)
- Fixtures in `conftest.py` files at appropriate scope levels
- No generic helper modules; use properly-scoped fixtures

### Development
- `just run <args>`: Run menv in dev mode
- `just check`: Format and lint
