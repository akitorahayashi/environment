# Contributing

## Contribution Policies

### Coding Standards

Rust:
- Formatter: `cargo fmt` (configuration in `rustfmt.toml`).
- Linter: `cargo clippy` with all warnings denied.
- Minimum Supported Rust Version: 1.90.0 (configuration in `clippy.toml`).
- Edition: 2024.

Python (development tooling):
- Dependency management: `uv sync` (configuration in `pyproject.toml`).

Shell Scripts:
- Formatter: `shfmt`.
- Linter: `shellcheck`.

Ansible:
- Linter: `ansible-lint`.

### Naming Conventions

Rust:
- Types: `PascalCase`
- Functions and Variables: `snake_case`
- Modules: `snake_case`, organized by ownership boundary (`cli/`, `app/`, `provisioning/`, `identity/`, `backup/`, `update/`, `host_fs/`, `test_support/`)
- Constants: `UPPER_SNAKE_CASE`

### Testing Strategies

Owner logic tests reside as self-contained unit tests within their respective owner modules inside a `#[cfg(test)]` block. Redundant logic coverage in external `tests/library/` integration tests is avoided.

## Procedural Verification

### Verify Commands

Local execution is triggered via:

```bash
just run <args>
```

All commands run before submitting changes are:

```bash
just check
just test
```

Ansible asset linting executes via:

```bash
uv run ansible-lint src/assets/ansible/
```
