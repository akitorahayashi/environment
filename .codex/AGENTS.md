# Environment Setup Project

## Snapshot
- macOS bootstrap flows through `ansible/playbook.yml`, orchestrated by the Makefile + `just` recipes.
- The Makefile installs system prerequisites (Homebrew, pyenv, uv, Ansible, just); never execute those targets from the agent environment.

## Entry Points
- `make base` – human-run bootstrap (creates `.env`, installs Python 3.12 via pyenv, pipx, uv sync, just).
- `make macbook` / `make mac-mini` – delegates to `just common`, applying the shared Ansible role sequence.
- `just` recipes – idempotent slices: `just python`, `just nodejs`, `just docker-images`, `just claude` / `gemini` / `codex`, profile switching via `just sw-p` / `just sw-w`, backups via `just backup-system` and `just backup-vscode-extensions`, validation via `just test`.
- `.github/actions/setup-base` – reusable CI composite action (Python 3.12, setup-just, setup-uv, `uv sync --frozen`).

## Implementation Notes
- Justfile forwards only `profile`, `config_dir_abs_path`, and `repo_root_path`; Ansible roles resolve concrete paths and fallback logic.
- Roles enforce symlink overwrites (`force: true`) to avoid stale links, including `~/.menv/scripts` → `ansible/scripts` so helpers run by name inside the uv-managed environment.
- Helper scripts assume uv discovery of `pyproject.toml`; no hardcoded repo paths or extra env vars such as `MENV_DIR`.
- Docker automation is opt-in through `just docker-images`; it hits the `docker` role with tag `docker`.

## Testing & Quality
- `just test` runs the pytest suite via `uv run pytest tests/`; dependencies live in `pyproject.toml` and install with `uv sync`.
- `just lint` and `just format` wrap ruff, black, shfmt, and ansible-lint for code hygiene.
