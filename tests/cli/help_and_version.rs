use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn version_flag_prints_package_version() {
    let ctx = TestContext::new();

    ctx.cli()
        .arg("--version")
        .assert()
        .success()
        .stdout(predicate::str::contains(env!("CARGO_PKG_VERSION")));
}

#[test]
fn help_lists_primary_commands() {
    let ctx = TestContext::new();

    ctx.cli().arg("--help").assert().success().stdout(
        predicate::str::contains("create")
            .and(predicate::str::contains("make"))
            .and(predicate::str::contains("list"))
            .and(predicate::str::contains("config"))
            .and(predicate::str::contains("switch"))
            .and(predicate::str::contains("update"))
            .and(predicate::str::contains("backup")),
    );
}

#[test]
fn help_omits_internal_command() {
    let ctx = TestContext::new();

    ctx.cli().arg("--help").assert().success().stdout(predicate::str::contains("internal").not());
}

#[test]
fn internal_help_lists_only_supported_subcommands() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["internal", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("shell").and(predicate::str::contains("vcs")));
}

#[test]
fn no_args_shows_help() {
    let ctx = TestContext::new();

    ctx.cli().assert().failure().stderr(predicate::str::contains("Usage"));
}
