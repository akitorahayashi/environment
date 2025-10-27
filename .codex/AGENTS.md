# Environment Setup Project

## Project Overview
A comprehensive automation project for setting up consistent macOS development environments across different machines (MacBook and Mac mini). This project uses Ansible playbooks to automate the installation and configuration of development tools, system settings, and configurations.

## Quick Start Guide

### Entry Points
1. **`Makefile`** - Initial setup entry point (you should not execute)
   - `make base`: Installs pyenv, Python 3.12, pipx, uv, Ansible, and just
   - `make macbook` / `make mac-mini`: Runs full machine-specific setup

2. **`justfile`** - Individual task runner and command orchestrator
   - Individual component setup commands (`just *`, `just mbk-*`, `just mmn-*`)
   - Profile switching (`just sw-p` / `just sw-w`)
   - Backup utilities (`just backup-*`)
   - Role additions and customizations

3. **`.github/actions/setup-base`** - CI composite action for consistent base environment setup
   - Python 3.12 with pip caching
   - Just command runner via `extractions/setup-just@v2`
   - Pipx and uv package managers
   - Ansible dependencies via `uv sync --frozen`

## Design Rules

### Configuration Path Resolution
**Core Principle**: justfile passes only profile name and base paths; Ansible roles handle all path resolution and fallback logic.

**Rules**:
- **justfile**: Pass `profile`, `config_dir_abs_path`, and `repo_root_path` only
- **Common configs**: Use `{{config_dir_abs_path}}` (e.g., `{{config_dir_abs_path}}/vcs/git/.gitconfig`)
- **Profile configs**: Use `{{repo_root_path}}/config/profiles/{{profile}}` (e.g., `{{repo_root_path}}/config/profiles/{{profile}}/cask/Brewfile`)
- **Fallback logic**: Roles must implement profile-specific → common fallback for optional overrides
- **No hardcoded paths**: Avoid embedding specific config subdirectories in justfile

### Python Script Execution Model
**Core Principle**: Helper scripts are location-agnostic and accessed via symlinks in `~/.menv/scripts/`, eliminating dependency on the repository's physical location.

**Rules**:
- **Dynamic Symlinks**: Ansible creates `~/.menv/scripts` as a symlink to `{{ repo_root_path }}/ansible/scripts`
- **PATH Configuration**: `.zprofile` adds `$HOME/.menv/scripts/shell` to `PATH`
- **Script Execution**: Python helper scripts (e.g., `gen_gemini_aliases.py`, `gen_slash_aliases.py`) are invoked directly by name from shell aliases
- **Environment Management**: `uv` automatically detects `pyproject.toml` in the repository root, activates the project-local virtual environment, and executes the script within that environment
- **No Hardcoding**: No hardcoded paths; all resolution uses symlinks that always point to the active repository
- **No Environment Variables**: Scripts don't depend on `MENV_DIR` or similar variables; the symlink ensures the correct location

### tests/ Directory Rules

To keep the repository lightweight while enabling richer validation, the `tests/` tree now relies on `pytest` with optional dependencies scoped to that directory.

- **Dependency Isolation:** Dependencies declared in root `pyproject.toml`; install via `uv sync` when you need the full suite.
- **Test Style:** All tests use pytest with fixtures and parametrization for efficient validation.
- **Execution:** Run tests via `just test` command, which executes `uv run pytest tests/` with proper dependency management.
- **Structure Mirroring:** Keep parity between source directories and their companion test modules (e.g., `ansible/roles/python/` ↔ `tests/ansible/test_role_integrity.py`).
- **Test Coverage:** Includes justfile ↔ Ansible tag validation and Ansible file reference integrity checks.
- **Fixture Organization:** Define fixtures at appropriate scope levels in conftest.py files:
  - `tests/conftest.py`: Global fixtures shared across all test domains
  - `tests/ansible/conftest.py`: Ansible-specific fixtures (playbook parsing, role validation)
  - `tests/config/conftest.py`: Configuration validation fixtures
  - **No helper utilities:** Avoid generic helper/utils modules; use properly-scoped fixtures instead

### CI Orchestration

CI/CD pipeline orchestration is centrally managed in the `ci-workflows.yml` file.
Each module defines its workflows in separate YAML files, specifying module-specific tasks and jobs.

### CI Environment Setup

All CI workflows use the reusable `.github/actions/setup-base` composite action for consistent base environment setup

This ensures consistent tooling across all CI jobs while leveraging GitHub Actions' caching and optimization features.

### Symlink Enforcement
**Core Principle**: Any automation that creates symbolic links must overwrite the destination regardless of its current state.

**Rules**:
- Always set `force: true` (or the equivalent) when creating symlinks so existing files, directories, or links are replaced.
- Do not skip symlink creation merely because the destination already exists; the task must re-run to guarantee the link points at the intended target.
- Treat broken symlinks as unacceptable debt—rewriting links is lightweight and prevents configuration drift.

**Rationale**:
- We observed a skipped symlink task during `just claude`, revealing that conditional guards can leave stale or broken links in place.
- Source paths change over time; unconditional recreation ensures our configuration always converges to the desired state.
- This policy keeps developer environments predictable and reduces time spent debugging missing or outdated resources.

### Repository Location Independence
**Core Principle**: The entire setup must work regardless of where the repository is cloned or moved.

**Rules**:
- **No Hardcoded Paths**: Never embed specific filesystem paths (e.g., `/Users/username/menv`) in shell configs, aliases, or scripts
- **Dynamic Resolution**: Use the `menv` wrapper or `~/.menv` symlinks for all repository references
- **Symlink Strategy**: Critical paths use symlinks:
  - `~/.menv` → actual repository location (managed by installer/migration logic)
  - `~/.menv/scripts` → `{{ repo_root_path }}/ansible/scripts` (managed by Ansible)
  - `~/.menv/alias` → aliasing directory (managed by Ansible)
- **Testing**: All setup must be validated on fresh machines and after repository relocation