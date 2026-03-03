# Contributing

## Contribution Policies

### Coding Standards

- Formatter: `ruff format` (configuration in `pyproject.toml`).
- Linter: `ruff check` with all warnings enabled (configuration in `pyproject.toml`).
- Type Checker: `mypy` for static type checking.
- Shell Scripts: `shfmt` for formatting, `shellcheck` for linting.
- Ansible: `ansible-lint` for playbook validation.

### Naming Conventions

- Classes: `PascalCase`
- Functions and Variables: `snake_case`
- Modules: `snake_case`, organized by feature domain (`commands/`, `providers/`, `ansible/`)
- Constants: `UPPER_SNAKE_CASE`

### Adding Tests

- Unit tests: located in `tests/unit/` and use `pytest` with fixtures.
- Integration tests: located in `tests/intg/` for end-to-end validation.
- Test naming: `test_*.py` files, test functions prefixed with `test_`.
- Use `pytest-mock` for mocking and `pytest-cov` for coverage reporting.

### Configuration Files

| File | Purpose |
|------|---------|
| `pyproject.toml` | Project metadata, dependencies, and tool configuration |
| `justfile` | Development task automation |
| `.python-version` | Pinned Python version |

## Procedural Verification

### Verify Commands

All commands are run before submitting changes:

```bash
just check
just test
```

Or individually:

```bash
uv run ruff format src/ tests/
uv run ruff check src/ tests/
uv run mypy src/ tests/
uv run pytest tests/unit/
uv run pytest tests/intg/
```

For shell scripts and Ansible:

```bash
shellcheck src/menv/*.sh
uv run ansible-lint src/menv/ansible/
```
