//! CLI contract tests for the `create` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn create_help_shows_overwrite_flag() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["create", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--overwrite"));
}

#[test]
fn create_help_shows_verbose_flag() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["create", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--verbose"));
}
