# Integration Tests

## Structure

Integration tests follow the `jlo/tests` contract model.

```text
tests/
    harness/               # Shared fixtures (no tests)
        test_context.rs      # TestContext
    cli.rs
    cli/                   # CLI behavior contracts
        backup.rs
        config.rs
        create.rs
        help_and_version.rs
        list.rs
        make.rs
        switch.rs
        update.rs
    library.rs
    library/               # Public API contracts
        backup_target.rs
        domain_exports.rs
    adapters.rs
    adapters/              # Adapter behavior contracts
        packaging.rs
        vcs.rs
        version.rs
    runtime.rs
    runtime/               # Binary invocation contracts
    security.rs
    security/              # Input validation contracts
```

## Contract Granularity

One behavior contract per file.
Multiple `#[test]` functions in one file validate the same contract.

## Shared Harness

```rust
use crate::harness::TestContext;

#[test]
fn my_contract() {
    let ctx = TestContext::new();
    ctx.cli().arg("--help").assert().success();
}
```

## Running

```bash
cargo test --all-targets --all-features
cargo test --test cli
cargo test --test library
cargo test --test adapters
cargo test --test runtime
cargo test --test security
```
