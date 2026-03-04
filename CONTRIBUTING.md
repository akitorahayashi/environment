# Contributing

## Contribution Policies

### Coding Standards

Rust:
- Formatter: `cargo fmt` (configuration in `rustfmt.toml`).
- Linter: `cargo clippy` with all warnings denied.
- Minimum Supported Rust Version: 1.90.0 (configuration in `clippy.toml`).
- Edition: 2024.

Python (legacy launcher surface):
- Formatter: `ruff format` (configuration in `pyproject.toml`).
- Linter: `ruff check` with all warnings enabled (configuration in `pyproject.toml`).
- Type Checker: `mypy` for static type checking.

Shell Scripts:
- Formatter: `shfmt`.
- Linter: `shellcheck`.

Ansible:
- Linter: `ansible-lint`.

### Naming Conventions

Rust:
- Types: `PascalCase`
- Functions and Variables: `snake_case`
- Modules: `snake_case`, organized by layer (`app/`, `domain/`, `adapters/`)
- Constants: `UPPER_SNAKE_CASE`

Python:
- Classes: `PascalCase`
- Functions and Variables: `snake_case`
- Modules: `snake_case`

### Configuration Files

| File | Purpose |
|------|---------|
| `Cargo.toml` | Rust package metadata and dependencies |
| `clippy.toml` | Clippy linter configuration |
| `rustfmt.toml` | Rust formatter configuration |
| `rust-toolchain.toml` | Rust toolchain version pinning |
| `mise.toml` | Development tool version management |
| `pyproject.toml` | Python metadata and packaging |
| `justfile` | Development task automation |

## Procedural Verification

### Verify Commands

All commands are run before submitting changes:

```bash
just check
just test
```

For Python legacy surface:

```bash
just py-check
just py-test
```

For shell scripts and Ansible:

```bash
shellcheck src/menv/*.sh
uv run ansible-lint src/menv/ansible/
```
