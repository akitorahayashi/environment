//! CLI contract tests for the `switch` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn switch_success_with_git() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let id_file = ctx.work_dir().join(".config/mev/identity.json");
    std::fs::create_dir_all(id_file.parent().ok_or("identity file path has no parent directory")?)?;
    std::fs::write(
        &id_file,
        r#"{"personal":{"name":"","email":""},"work":{"name":"John Doe","email":"john@example.com"}}"#,
    )?;

    let cmd_log = ctx.work_dir().join("cmd_log.txt");

    ctx.create_mock_command("git", "#!/bin/sh\necho \"git $@\" >> \"$CMD_LOG\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .env("CMD_LOG", &cmd_log)
        .args(["switch", "work"])
        .assert()
        .success();

    let log_content = std::fs::read_to_string(cmd_log)?;
    assert!(log_content.contains("git config --global user.name John Doe"));
    Ok(())
}

#[test]
fn switch_fails_if_identity_not_configured() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let id_file = ctx.work_dir().join(".config/mev/identity.json");
    std::fs::create_dir_all(id_file.parent().ok_or("identity file path has no parent directory")?)?;
    std::fs::write(
        &id_file,
        r#"{"personal":{"name":"","email":""},"work":{"name":"","email":""}}"#,
    )?;

    ctx.cli()
        .args(["switch", "work"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("work identity is not configured"));
    Ok(())
}
