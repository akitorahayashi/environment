# Architecture

`menv` follows a layered architecture so that each tool does one job well and the overall workflow stays reproducible.

## Flow
1. **Makefile** bootstraps prerequisites (`make base`) and kicks off the first Just run (`make macbook`, `make mac-mini`).
2. **Just** exposes concise recipes that translate into Ansible tags using the hidden `_run_ansible` helper. Each recipe supplies `profile`, `repo_root_path`, and the tag to execute.
3. **Ansible** applies roles declared in `ansible/playbook.yml`. Role tags (`brew-formulae`, `python-platform`, etc.) mirror the Just recipes and are validated by automated tests.

## Profiles and Configuration Resolution
- Profiles distinguish shared configuration (`config/common`) from machine-specific overrides (`config/profiles/<profile>`). For example, the `brew` role looks for `config/profiles/macbook/...` first and falls back to `config/common`.
- Symlinks created by roles always use `force: true`, ensuring re-runs converge even if files already exist.
- The `repo_root_path` variable allows scripts and templates to remain location-agnostic. Critical paths are exposed through symlinks in `~/.menv`.

## Ansible Roles
Each role has its own documentation page under `docs/roles/`:
- [brew](./roles/brew.md)
- [shell](./roles/shell.md)
- [vcs](./roles/vcs.md)
- [gh](./roles/gh.md)
- [ssh](./roles/ssh.md)
- [system](./roles/system.md)
- [ruby](./roles/ruby.md)
- [rust](./roles/rust.md)
- [editor](./roles/editor.md)
- [python](./roles/python.md)
- [nodejs](./roles/nodejs.md)
- [slash](./roles/slash.md)
- [docker](./roles/docker.md)
- [coderabbit](./roles/coderabbit.md)
- [menv](./roles/menv.md)

The playbook orchestrates them in dependency-aware order: platform prerequisites (Homebrew, languages) load before editors and AI tooling, finishing with system defaults and optional Docker images.

Refer to [Configuration](./configuration.md) for details on the files each role consumes.
