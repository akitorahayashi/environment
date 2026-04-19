# Testing

## Structure

Testing is organized by ownership boundary and externally observable behavior:

| Boundary | Location | Purpose |
|---|---|---|
| Owner unit tests | `src/provisioning/**/*.rs`, `src/identity/**/*.rs`, `src/backup/**/*.rs`, `src/update/**/*.rs` | Owner-local behavior verification within `#[cfg(test)]` blocks |
| Integration tests | `tests/library/` | Library API contracts and multi-component interaction |
| Runtime tests | `tests/runtime.rs` | End-to-end CLI execution scenarios |
| Security tests | `tests/security/` | Input validation and security boundary enforcement |
| Test support | `src/test_support/` | Crate-wide in-process test doubles reused across owners |

## Principles

Owner logic tests reside as self-contained unit tests inside each owner module using `#[cfg(test)]`. Redundant logic coverage in external `tests/library/` integration tests is avoided.

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
cargo test provisioning::tag_selection
```

## Test Doubles

The `src/test_support/` boundary provides crate-wide in-process test doubles:

- `provisioning`: fake implementation for provisioning contracts (`ProvisioningCatalog`, `ProvisioningRunner`, `RoleConfigLocator`)
- `host_fs`: filesystem operation fake

These doubles enable testing without external dependencies or side effects.
