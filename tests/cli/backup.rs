//! CLI contract tests for the `backup` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn backup_system_success() {
    let ctx = TestContext::new();

    let defs_dir = ctx.work_dir().join(".config/mev/roles/system/global/definitions");
    std::fs::create_dir_all(&defs_dir).unwrap();
    std::fs::write(
        defs_dir.join("test.yml"),
        r#"[{ "key": "AppleShowAllFiles", "type": "bool", "default": false }]"#,
    )
    .unwrap();

    ctx.create_mock_command("defaults", "#!/bin/sh\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "system"])
        .assert()
        .success();

    let output_file = ctx.work_dir().join(".config/mev/roles/system/global/system.yml");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file).unwrap();
    assert!(content.contains("AppleShowAllFiles"));
}

#[test]
fn backup_vscode_success() {
    let ctx = TestContext::new();

    ctx.create_mock_command("code", "#!/bin/sh\necho \"ms-python.python\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "vscode"])
        .assert()
        .success();

    let output_file = ctx.work_dir().join(".config/mev/roles/editor/global/vscode-extensions.json");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file).unwrap();
    assert!(content.contains("ms-python.python"));
}

#[test]
fn backup_system_failure_no_definitions() {
    let ctx = TestContext::new();

    let defs_dir = ctx.work_dir().join(".config/mev/roles/system/global/definitions");
    std::fs::create_dir_all(&defs_dir).unwrap();
    // Directory exists, but no definitions in it

    ctx.cli()
        .args(["backup", "system"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("no setting definitions found"));
}
