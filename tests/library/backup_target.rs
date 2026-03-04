//! Verify backup domain types are accessible and resolve correctly.

#[test]
fn backup_target_resolves_system() {
    let target = mev::domain::backup_target::BackupTarget::from_input("system");
    assert!(target.is_some());
    assert_eq!(target.unwrap().name(), "system");
}

#[test]
fn backup_target_resolves_vscode() {
    let target = mev::domain::backup_target::BackupTarget::from_input("vscode");
    assert!(target.is_some());
    assert_eq!(target.unwrap().name(), "vscode");
}

#[test]
fn backup_target_resolves_vscode_extensions_alias() {
    let target = mev::domain::backup_target::BackupTarget::from_input("vscode-extensions");
    assert!(target.is_some());
    assert_eq!(target.unwrap().name(), "vscode");
}

#[test]
fn backup_target_rejects_unknown() {
    assert!(mev::domain::backup_target::BackupTarget::from_input("unknown").is_none());
}

#[test]
fn backup_target_all_returns_expected_set() {
    let all = mev::domain::backup_target::BackupTarget::all();
    assert_eq!(all.len(), 2);
}
