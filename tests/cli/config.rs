//! CLI contract tests for the `config` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn config_show_does_not_require_ansible_assets() {
    // config show should fail with "no configuration found" (config-level error),
    // not with "ansible asset directory not found" (asset resolution error).
    let ctx = TestContext::new();

    ctx.cli()
        .args(["config", "show"])
        .assert()
        .failure()
        .stderr(
            predicate::str::contains("no configuration found")
                .or(predicate::str::contains("configuration error")),
        )
        .stderr(predicate::str::contains("ansible").not());
}

#[test]
fn config_show_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["config", "show", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Display current VCS identity"));
}

#[test]
fn config_set_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["config", "set", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Set VCS identity"));
}

#[test]
fn config_create_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["config", "create", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deploy role configs"));
}
