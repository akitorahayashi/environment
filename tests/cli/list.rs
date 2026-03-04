//! CLI contract tests for the `list` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn list_help_shows_description() {
    let ctx = TestContext::new();
    ctx.cli().args(["list", "--help"]).assert().success().stdout(predicate::str::contains("tag"));
}

#[test]
fn list_alias_ls_is_accepted() {
    let ctx = TestContext::new();
    ctx.cli().args(["ls", "--help"]).assert().success();
}

#[test]
fn list_visible_in_main_help() {
    let ctx = TestContext::new();
    ctx.cli().arg("--help").assert().success().stdout(predicate::str::contains("list"));
}
