# Environment Setup Project

## Project Overview
A comprehensive automation project for setting up consistent macOS development environments across different machines (MacBook and Mac mini). This project uses Ansible playbooks to automate the installation and configuration of development tools, system settings, and configurations.

## Quick Start Guide

### Entry Points
1. **`Makefile`** - Initial setup entry point (you should not execute)
   - `make base`: Installs Homebrew, Just, and Ansible
   - `make macbook` / `make mac-mini`: Runs full machine-specific setup

2. **`justfile`** - Individual task runner and command orchestrator
   - Individual component setup commands (`just cmn-*`, `just mbk-*`, `just mmn-*`)
   - Profile switching (`just sw-p` / `just sw-w`)
   - Backup utilities (`just cmn-backup-*`)
   - Role additions and customizations
   - Service orchestration now lives in the sibling `universe/` repository; see `universe/justfile` for Compose/Ansible helpers

3. **`README.md`** - Comprehensive project documentation
   - Directory structure and architecture explanation
   - Usage instructions and command reference
   - Detailed Ansible role functionality

## Design Rules

### Configuration Path Resolution
**Core Principle**: justfile passes only profile name and base paths; Ansible roles handle all path resolution and fallback logic.

**Rules**:
- **justfile**: Pass `profile`, `config_dir_abs_path`, and `repo_root_path` only
- **Common configs**: Use `{{config_dir_abs_path}}` (e.g., `{{config_dir_abs_path}}/vcs/git/.gitconfig`)
- **Profile configs**: Use `{{repo_root_path}}/config/profiles/{{profile}}` (e.g., `{{repo_root_path}}/config/profiles/{{profile}}/cask/Brewfile`)
- **Fallback logic**: Roles must implement profile-specific → common fallback for optional overrides
- **No hardcoded paths**: Avoid embedding specific config subdirectories in justfile

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

### Symlink Enforcement
**Core Principle**: Any automation that creates symbolic links must overwrite the destination regardless of its current state.

**Rules**:
- Always set `force: true` (or the equivalent) when creating symlinks so existing files, directories, or links are replaced.
- Do not skip symlink creation merely because the destination already exists; the task must re-run to guarantee the link points at the intended target.
- Treat broken symlinks as unacceptable debt—rewriting links is lightweight and prevents configuration drift.

**Rationale**:
- We observed a skipped symlink task during `just cmn-claude`, revealing that conditional guards can leave stale or broken links in place.
- Source paths change over time; unconditional recreation ensures our configuration always converges to the desired state.
- This policy keeps developer environments predictable and reduces time spent debugging missing or outdated resources.
