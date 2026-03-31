//! CLI contract tests for the `switch` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn switch_success_with_git_and_jj() {
    let ctx = TestContext::new();

    let id_file = ctx.work_dir().join(".config/mev/identity.json");
    std::fs::create_dir_all(id_file.parent().unwrap()).unwrap();
    std::fs::write(
        &id_file,
        r#"{"personal":{"name":"","email":""},"work":{"name":"John Doe","email":"john@example.com"}}"#,
    )
    .unwrap();

    let cmd_log = ctx.work_dir().join("cmd_log.txt");

    ctx.create_mock_command("git", "#!/bin/sh\necho \"git $@\" >> \"$CMD_LOG\"\nexit 0\n");
    ctx.create_mock_command("jj", "#!/bin/sh\necho \"jj $@\" >> \"$CMD_LOG\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .env("CMD_LOG", &cmd_log)
        .args(["switch", "work"])
        .assert()
        .success();

    let log_content = std::fs::read_to_string(cmd_log).unwrap();
    assert!(log_content.contains("git config --global user.name John Doe"));
    assert!(log_content.contains("jj config set --user user.name John Doe"));
}

#[test]
fn switch_fails_if_identity_not_configured() {
    let ctx = TestContext::new();

    let id_file = ctx.work_dir().join(".config/mev/identity.json");
    std::fs::create_dir_all(id_file.parent().unwrap()).unwrap();
    std::fs::write(
        &id_file,
        r#"{"personal":{"name":"","email":""},"work":{"name":"","email":""}}"#,
    )
    .unwrap();

    ctx.cli()
        .args(["switch", "work"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("work identity is not configured"));
}
