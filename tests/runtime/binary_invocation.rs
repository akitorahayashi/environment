//! Binary invocation contracts.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn binary_exists_and_runs() {
    let ctx = TestContext::new();
    ctx.cli().arg("--version").assert().success().stdout(predicate::str::contains("mev"));
}

#[test]
fn unknown_subcommand_fails() {
    let ctx = TestContext::new();
    ctx.cli()
        .arg("nonexistent-command")
        .assert()
        .failure()
        .stderr(predicate::str::is_empty().not());
}
