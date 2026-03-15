//! CLI contract tests for the `config` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn config_deploy_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["config", "deploy", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deploy role configs"));
}
