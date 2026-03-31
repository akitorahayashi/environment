# Testing

## Structure

Testing is organized into distinct layers aligned with the architecture:

| Layer | Location | Purpose |
|---|---|---|
| Unit tests | `src/domain/**/*.rs` | Domain logic verification within `#[cfg(test)]` blocks |
| Integration tests | `tests/library/` | Library API contracts and multi-component interaction |
| Runtime tests | `tests/runtime.rs` | End-to-end CLI execution scenarios |
| Security tests | `tests/security/` | Input validation and security boundary enforcement |
| Test doubles | `src/testing/` | In-process mocks and builders for test isolation |

## Principles

Domain logic tests reside as self-contained unit tests within their respective `src/domain/` modules inside a `#[cfg(test)]` block. Redundant logic coverage in external `tests/library/` integration tests is avoided.

Tests assert externally observable behavior at the owning boundary, never duplicated knowledge of internal implementation or generated structure.

Temporary operations are confined to the project root unless external constraints apply (e.g., use `./.tmp/` instead of `/tmp/`).

## Execution

Run all tests:

```bash
just test
```

Run specific test categories:

```bash
cargo test --test library     # Library integration tests
cargo test --test runtime     # Runtime CLI tests
cargo test --test security    # Security tests
```

Run tests in a specific module:

```bash
cargo test domain::tag        # Domain unit tests for tag module
```

## Test Doubles

The `src/testing/` module provides in-process test doubles:

- `ansible`: Mock Ansible executor and locator implementations
- `fs`: Filesystem operation mocks

These doubles enable testing without external dependencies or side effects.
