use assert_cmd::cargo_bin_cmd;
use predicates::prelude::*;

#[test]
fn gen_gemini_aliases_produces_expected_output() {
    let output =
        cargo_bin_cmd!("menv-internal").args(["shell", "gen-gemini-aliases"]).assert().success();

    let stdout = String::from_utf8(output.get_output().stdout.clone()).unwrap();
    let lines: Vec<&str> = stdout.trim().lines().collect();

    // 5 models × 6 options = 30 aliases
    assert_eq!(lines.len(), 30, "expected 30 aliases, got {}", lines.len());

    assert!(lines.iter().all(|l| l.starts_with("alias ")));
    assert!(lines.contains(&r#"alias gm-pr="gemini -m gemini-3.1-pro-preview""#));
    assert!(lines.contains(&r#"alias gm-fl="gemini -m gemini-3-flash-preview""#));
    assert!(lines.contains(&r#"alias gm-pr-y="gemini -m gemini-3.1-pro-preview -y""#));
    assert!(lines.contains(&r#"alias gm-fl-ap="gemini -m gemini-3-flash-preview -a -p""#));
}

#[test]
fn gen_vscode_workspace_creates_file() {
    let dir = tempfile::tempdir().unwrap();
    cargo_bin_cmd!("menv-internal")
        .current_dir(dir.path())
        .args(["shell", "gen-vscode-workspace", "../path1", "/abs/path2"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Workspace file created"));

    let ws_file = dir.path().join("workspace.code-workspace");
    assert!(ws_file.exists());

    let content: serde_json::Value =
        serde_json::from_str(&std::fs::read_to_string(&ws_file).unwrap()).unwrap();
    let folders = content["folders"].as_array().unwrap();
    assert_eq!(folders.len(), 2);
    assert_eq!(folders[0]["path"], "../path1");
    assert_eq!(folders[1]["path"], "/abs/path2");
}
