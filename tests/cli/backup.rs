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

    let vscode_settings_dir = ctx.work_dir().join("Library/Application Support/Code/User");
    std::fs::create_dir_all(&vscode_settings_dir)?;
    std::fs::write(vscode_settings_dir.join("settings.json"), "{}\n")?;
    std::fs::write(vscode_settings_dir.join("keybindings.json"), "[]\n")?;

    ctx.create_mock_command("code", "#!/bin/sh\necho \"ms-python.python\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "vscode"])
        .assert()
        .success();

    let output_file = ctx.work_dir().join(".config/mev/roles/editor/global/vscode/extensions.json");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file)?;
    assert!(content.contains("ms-python.python"));

    let settings_output =
        ctx.work_dir().join(".config/mev/roles/editor/global/vscode/settings.json");
    assert!(settings_output.exists());
    let keybindings_output =
        ctx.work_dir().join(".config/mev/roles/editor/global/vscode/keybindings.json");
    assert!(keybindings_output.exists());
    Ok(())
}

#[test]
fn backup_vscode_keeps_managed_settings_symlink_unchanged() -> Result<(), Box<dyn std::error::Error>>
{
    let ctx = TestContext::new();

    let managed_settings =
        ctx.work_dir().join(".config/mev/roles/editor/global/vscode/settings.json");
    let managed_keybindings =
        ctx.work_dir().join(".config/mev/roles/editor/global/vscode/keybindings.json");
    std::fs::create_dir_all(managed_settings.parent().unwrap())?;
    std::fs::write(&managed_settings, "{\"workbench.colorTheme\":\"Default Light+\"}\n")?;
    std::fs::write(&managed_keybindings, "[]\n")?;

    let vscode_settings_dir = ctx.work_dir().join("Library/Application Support/Code/User");
    std::fs::create_dir_all(&vscode_settings_dir)?;
    std::os::unix::fs::symlink(&managed_settings, vscode_settings_dir.join("settings.json"))?;
    std::os::unix::fs::symlink(&managed_keybindings, vscode_settings_dir.join("keybindings.json"))?;

    ctx.create_mock_command("code", "#!/bin/sh\necho \"ms-python.python\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "co"])
        .assert()
        .success()
        .stdout(predicate::str::contains("VS Code settings already managed"))
        .stdout(predicate::str::contains("VS Code keybindings already managed"));

    let content = std::fs::read_to_string(managed_settings)?;
    assert!(content.contains("Default Light+"));
    let keybindings_content = std::fs::read_to_string(managed_keybindings)?;
    assert_eq!(keybindings_content, "[]\n");
    Ok(())
}

#[test]
fn backup_antigravity_ide_success_via_canonical_name() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let antigravity_ide_settings_dir =
        ctx.work_dir().join("Library/Application Support/Antigravity IDE/User");
    std::fs::create_dir_all(&antigravity_ide_settings_dir)?;
    std::fs::write(antigravity_ide_settings_dir.join("settings.json"), "{}\n")?;
    std::fs::write(antigravity_ide_settings_dir.join("keybindings.json"), "[]\n")?;

    ctx.create_mock_command("agy-ide", "#!/bin/sh\necho \"mushan.vscode-paste-image\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "antigravity-ide"])
        .assert()
        .success();

    let output_file =
        ctx.work_dir().join(".config/mev/roles/editor/global/antigravity-ide/extensions.json");
    assert!(output_file.exists());
    let content = std::fs::read_to_string(output_file)?;
    assert!(content.contains("mushan.vscode-paste-image"));

    let settings_output =
        ctx.work_dir().join(".config/mev/roles/editor/global/antigravity-ide/settings.json");
    assert!(settings_output.exists());
    let keybindings_output =
        ctx.work_dir().join(".config/mev/roles/editor/global/antigravity-ide/keybindings.json");
    assert!(keybindings_output.exists());
    Ok(())
}

#[test]
fn backup_antigravity_ide_success_via_agi_alias() -> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let antigravity_ide_settings_dir =
        ctx.work_dir().join("Library/Application Support/Antigravity IDE/User");
    std::fs::create_dir_all(&antigravity_ide_settings_dir)?;
    std::fs::write(antigravity_ide_settings_dir.join("settings.json"), "{}\n")?;
    std::fs::write(antigravity_ide_settings_dir.join("keybindings.json"), "[]\n")?;

    ctx.create_mock_command("agy-ide", "#!/bin/sh\necho \"mushan.vscode-paste-image\"\nexit 0\n");

    ctx.cli().env("PATH", ctx.path_with_mock_commands()).args(["backup", "agi"]).assert().success();

    let output_file =
        ctx.work_dir().join(".config/mev/roles/editor/global/antigravity-ide/extensions.json");
    assert!(output_file.exists());

    Ok(())
}

#[test]
fn backup_antigravity_ide_keeps_managed_settings_symlink_unchanged()
-> Result<(), Box<dyn std::error::Error>> {
    let ctx = TestContext::new();

    let managed_settings =
        ctx.work_dir().join(".config/mev/roles/editor/global/antigravity-ide/settings.json");
    let managed_keybindings =
        ctx.work_dir().join(".config/mev/roles/editor/global/antigravity-ide/keybindings.json");
    std::fs::create_dir_all(managed_settings.parent().unwrap())?;
    std::fs::write(&managed_settings, "{\"workbench.colorTheme\":\"Default Light+\"}\n")?;
    std::fs::write(&managed_keybindings, "[]\n")?;

    let antigravity_ide_settings_dir =
        ctx.work_dir().join("Library/Application Support/Antigravity IDE/User");
    std::fs::create_dir_all(&antigravity_ide_settings_dir)?;
    std::os::unix::fs::symlink(
        &managed_settings,
        antigravity_ide_settings_dir.join("settings.json"),
    )?;
    std::os::unix::fs::symlink(
        &managed_keybindings,
        antigravity_ide_settings_dir.join("keybindings.json"),
    )?;

    ctx.create_mock_command("agy-ide", "#!/bin/sh\necho \"mushan.vscode-paste-image\"\nexit 0\n");

    ctx.cli()
        .env("PATH", ctx.path_with_mock_commands())
        .args(["backup", "antigravity-ide"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Antigravity IDE settings already managed"))
        .stdout(predicate::str::contains("Antigravity IDE keybindings already managed"));

    let content = std::fs::read_to_string(managed_settings)?;
    assert!(content.contains("Default Light+"));
    let keybindings_content = std::fs::read_to_string(managed_keybindings)?;
    assert_eq!(keybindings_content, "[]\n");
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
