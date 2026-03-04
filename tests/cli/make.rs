//! CLI contract tests for the `make` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn make_help_shows_overwrite_flag() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["make", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--overwrite"));
}

#[test]
fn make_help_shows_verbose_flag() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["make", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--verbose"));
}
