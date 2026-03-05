//! CLI contract tests for the `backup` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn backup_help_shows_target_argument() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["backup", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("target"));
}

#[test]
fn backup_alias_bk_is_accepted() {
    // The alias should resolve without "unrecognized subcommand" errors.
    // It will fail due to missing ansible assets, but it should not fail
    // on subcommand resolution.
    let ctx = TestContext::new();

    ctx.cli()
        .args(["bk", "--list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available backup targets"));
}

#[test]
fn backup_list_shows_targets() {
    let ctx = TestContext::new();

    ctx.cli().args(["backup", "--list"]).assert().success().stdout(
        predicate::str::contains("system")
            .and(predicate::str::contains("vscode"))
            .and(predicate::str::contains("Available backup targets")),
    );
}

#[test]
fn backup_short_list_flag_shows_targets() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["backup", "-l"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available backup targets"));

    ctx.cli()
        .args(["backup", "--ls"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available backup targets"));
}

#[test]
fn backup_unknown_target_fails() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["backup", "nonexistent"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("unknown backup target"));
}

#[test]
fn backup_help_visible_in_main_help() {
    let ctx = TestContext::new();

    ctx.cli().arg("--help").assert().success().stdout(predicate::str::contains("backup"));
}
