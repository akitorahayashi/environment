//! CLI contract tests for the `update` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn update_prints_current_version() {
    let ctx = TestContext::new();

    // Update will print current version even if remote check fails.
    ctx.cli().arg("update").assert().success().stdout(predicate::str::contains("Current version"));
}

#[test]
fn update_alias_u_is_accepted() {
    let ctx = TestContext::new();

    ctx.cli().arg("u").assert().success().stdout(predicate::str::contains("Current version"));
}
