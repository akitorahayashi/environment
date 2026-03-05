//! CLI contract tests for the `switch` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn switch_help_shows_identity_argument() {
    let ctx = TestContext::new();
    ctx.cli()
        .args(["switch", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("IDENTITY"));
}

#[test]
fn switch_alias_sw_is_accepted() {
    let ctx = TestContext::new();
    ctx.cli()
        .args(["sw", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("IDENTITY"));
}

#[test]
fn switch_requires_identity_argument() {
    let ctx = TestContext::new();
    ctx.cli()
        .arg("switch")
        .assert()
        .failure()
        .stderr(predicate::str::contains("IDENTITY").or(predicate::str::contains("required")));
}

#[test]
fn switch_without_config_fails_gracefully() {
    let ctx = TestContext::new();
    ctx.cli().args(["switch", "invalid"]).assert().failure();
}

#[test]
fn switch_help_visible_in_main_help() {
    let ctx = TestContext::new();
    ctx.cli()
        .arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains("switch"))
        .stdout(predicate::str::contains("sw"));
}
