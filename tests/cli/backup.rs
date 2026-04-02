//! CLI contract tests for the `backup` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn backup_system_success() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let defs_dir = ctx.work_dir().join(".config/mev/roles/system/global/definitions");
    std::fs::create_dir_all(&defs_dir)?;
    std::fs::write(
        defs_dir.join("test.yml"),
        r#"[{ "key": "AppleShowAllFiles", "type": "bool", "default": false }]"#,
    )?;

    ctx.create_mock_command("defaults", "#!/bin/sh\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "system"])
        .assert()
        .success();

    let output_file = ctx.work_dir().join(".config/mev/roles/system/global/system.yml");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file)?;
    assert!(content.contains("AppleShowAllFiles"));
    Ok(())
}

#[test]
fn backup_vscode_success() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    ctx.create_mock_command("code", "#!/bin/sh\necho \"ms-python.python\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "vscode"])
        .assert()
        .success();

    let output_file = ctx.work_dir().join(".config/mev/roles/editor/global/vscode-extensions.json");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file)?;
    assert!(content.contains("ms-python.python"));
    Ok(())
}

#[test]
fn backup_system_failure_no_definitions() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let defs_dir = ctx.work_dir().join(".config/mev/roles/system/global/definitions");
    std::fs::create_dir_all(&defs_dir)?;
    // Directory exists, but no definitions in it

    ctx.cli()
        .args(["backup", "system"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("no setting definitions found"));
    Ok(())
}

#[test]
fn backup_system_missing_key_fallback() {
    let ctx = TestContext::new();

    let defs_dir = ctx.work_dir().join(".config/mev/roles/system/global/definitions");
    std::fs::create_dir_all(&defs_dir).unwrap();
    std::fs::write(
        defs_dir.join("test.yml"),
        r#"[{ "key": "AppleShowAllFiles", "type": "bool", "default": true }]"#,
    )
    .unwrap();

    ctx.create_mock_command(
        "defaults",
        "#!/bin/sh\necho \"does not exist\"\n>&2 echo \"does not exist\"\nexit 1\n",
    );

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "system"])
        .assert()
        .success();

    let output_file = ctx.work_dir().join(".config/mev/roles/system/global/system.yml");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file).unwrap();
    assert!(content.contains("value: true"));
}

#[test]
fn backup_system_invalid_yaml() {
    let ctx = TestContext::new();

    let defs_dir = ctx.work_dir().join(".config/mev/roles/system/global/definitions");
    std::fs::create_dir_all(&defs_dir).unwrap();
    std::fs::write(defs_dir.join("test.yml"), "invalid: yaml: content: [").unwrap();

    ctx.cli()
        .args(["backup", "system"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("invalid YAML"));
}

#[test]
fn backup_system_fallback_to_package_defaults() {
    let ctx = TestContext::new();

    // Do not create a local definitions directory.
    // The application should fall back to the embedded package defaults.

    // Mock the `defaults` command so that when it reads the package defaults, it succeeds.
    ctx.create_mock_command("defaults", "#!/bin/sh\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "system"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Using package defaults"));
}
