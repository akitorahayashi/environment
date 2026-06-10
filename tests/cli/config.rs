//! CLI contract tests for the `config` command.

use crate::harness::TestContext;

#[test]
fn deploy_nested_editor_role_config() {
    let ctx = TestContext::new();

    ctx.cli().args(["config", "deploy", "editor/vscode"]).assert().success();

    assert!(ctx.work_dir().join(".config/mev/roles/editor/vscode/global/settings.json").exists());
    assert!(!ctx.work_dir().join(".config/mev/roles/editor/config").exists());
}

#[test]
fn deploy_nested_editor_role_accepts_hyphenated_external_name() {
    let ctx = TestContext::new();

    ctx.cli().args(["config", "deploy", "editor/antigravity-ide"]).assert().success();

    assert!(
        ctx.work_dir()
            .join(".config/mev/roles/editor/antigravity_ide/global/settings.json")
            .exists()
    );
}
