# Testing

`menv` uses pytest to validate both the Ansible automation and supporting scripts. All tests live under `tests/` and are executed inside the project’s `uv` environment.

## Running Tests
```zsh
just test
```
The recipe runs `uv run pytest tests/`, which respects configuration in `pyproject.toml` (`testpaths = ["tests"]`). Run it after modifying roles, scripts, or configuration files.

## Test Coverage
The suite focuses on preventing configuration drift and ensuring tag integrity:
- **Ansible integration tests** (`tests/ansible/`) parse the playbook and role tasks to confirm Just recipes map to declared tags and every static `src`/`lookup('file', ...)` reference points to an existing file.
- **Configuration validation** (`tests/config/`) asserts that editor settings, Rust tool manifests, slash command configs, and backup scripts remain well-formed.
- **Script behavior** tests verify helper CLIs such as `ansible/scripts/editor/backup-extensions.py`, `ansible/scripts/shell/ssh_manager.py`, and `ansible/scripts/shell/gen_gemini_aliases.py`.

Fixtures in `tests/conftest.py` (and role-specific subdirectories) mirror the repository layout, keeping tests concise while ensuring new files are picked up automatically.
