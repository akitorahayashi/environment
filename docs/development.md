# Development

Follow these guidelines when updating automation, roles, or scripts in `menv`.

## Code Style
- **Python:** Target Python 3.12. Use Black and Ruff (`just lint` runs Black in check mode and Ruff linting). Format on demand with `just format`, which also executes Black in write mode via `uv run black`.
- **Shell:** Keep scripts POSIX-compliant where possible. `just lint` applies ShellCheck, and `just format` runs `shfmt` across tracked shell files.
- **Ansible:** Structure roles under `ansible/roles/<role>`. Run `ansible-lint` via `just lint`/`just format` to catch style and best-practice issues.

## Automation Policies
- **Symlink Enforcement:** Any file or directory symlink created by a role must specify `force: true` (or remove and recreate) so re-runs replace stale links.
- **Python Script Execution Model:** Helper scripts reside under `ansible/scripts/` and are symlinked into `~/.menv/scripts`. Invoking them (for example `ssh_manager.py`) automatically runs within the project’s `uv` environment, so never hard-code repository paths.
- **Repository Location Independence:** Avoid embedding absolute paths. Use the `menv` wrapper, `$HOME/.menv` symlinks, or Ansible variables like `repo_root_path` to resolve resources dynamically.

## Recommended Workflow
1. Edit roles or scripts in the repository.
2. Regenerate documentation or configuration as needed (e.g., `just backup-system`).
3. Run `just lint` and `just test` before committing significant changes.
4. Document new behavior in the relevant files under `docs/` to keep the automation explainable.

See [Testing](./testing.md) for details on the pytest suite and how it validates tag alignment and configuration integrity.
