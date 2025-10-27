# Justfile Usage

The `justfile` exposes convenient recipes for running Ansible roles, switching profiles, and maintaining the automation. Just loads `.env` automatically (`set dotenv-load`) so role variables and secrets are available without additional export commands.

## How Recipes Work
Every recipe that configures the system eventually calls the hidden `_run_ansible` helper:
- It verifies `.env` exists and exports its values.
- It sets `ANSIBLE_CONFIG` to `ansible/ansible.cfg`.
- It executes `uv run ansible-playbook` with the requested tag, profile, and `repo_root_path` values.

Because tags match those declared in `ansible/playbook.yml`, you can target specific roles with confidence that tag validation tests cover the mapping.

## Common Setup
`just common` chains the core environment tasks in a deliberate order—shell first, then the `menv` wrapper, SSH, system defaults, VCS tooling, editors, languages, AI CLIs, and finally Homebrew formulae. Run it after `make base` or any time you need to re-converge a machine.

```zsh
just common
```

Notable component recipes invoked by `common` can also run individually:
- `just shell`, `just menv`, `just ssh` – dotfiles, wrapper script, and SSH configuration.
- `just git`, `just jj`, `just gh` – VCS tooling using the `vcs` and `gh` roles.
- `just python`, `just nodejs`, `just ruby`, `just rust` – language stacks driven by their roles and tags (`python-platform`, `nodejs-tools`, etc.).
- `just vscode`, `just cursor`, `just coderabbit` – editor experiences and the CodeRabbit CLI.
- `just brew-formulae` / `just brew-cask` – Homebrew packages backed by Brewfiles with profile fallback.

## Profile Switching
Use the VCS helpers when you need to hop between personal and work identities:
```zsh
just sw-p  # applies PERSONAL_VCS_* values from .env
just sw-w  # applies WORK_VCS_* values from .env
```
These recipes update both Git and JJ configuration files.

## Utilities and Maintenance
- `just backup-system` runs `ansible/scripts/system/backup-system.py` to export current macOS defaults.
- `just backup-vscode-extensions` captures installed VS Code extensions via `ansible/scripts/editor/backup-extensions.py`.
- `just lint` executes Black (check), Ruff, ShellCheck, and `ansible-lint`.
- `just format` formats Python, then reformats shell scripts with `shfmt`, and auto-fixes Ansible issues.
- `just test` runs the project’s pytest suite.
- `just clean` removes caches and ephemeral virtual environments.

Run `just help` for a generated list of all recipes, or inspect the `justfile` for chaining logic and tag associations.
