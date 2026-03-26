use mev_internal::app::commands::gh::{labels_deploy, labels_reset};
use mev_internal::testing::env_mock::create_mock_bin;
use serial_test::serial;
use std::fs;

fn create_gh_mock_script(log_path: &std::path::Path) -> String {
    format!(
        "#!/bin/sh\necho \"$@\" >> \"{}\"\nif [ \"$1\" = \"label\" ] && [ \"$2\" = \"list\" ]; then\n    echo \"bugs\"\nelse\n    exit 0\nfi",
        log_path.display()
    )
}

#[test]
#[serial(env_path)]
fn test_gh_labels_deploy() {
    let temp_dir = tempfile::tempdir().unwrap();
    let gh_log = temp_dir.path().join("gh_log.txt");

    let mock_script = create_gh_mock_script(&gh_log);

    let _path_guard = create_mock_bin("gh", &temp_dir, &mock_script);

    let args = labels_deploy::LabelsDeployArgs { repo: Some("owner/repo".to_string()) };

    labels_deploy::run(args).expect("deploy should succeed");

    let log_content = fs::read_to_string(gh_log).unwrap();
    assert!(log_content.contains("label list"));
    assert!(log_content.contains("label delete bugs"));
    assert!(log_content.contains("label create bugs"));
}

#[test]
#[serial(env_path)]
fn test_gh_labels_reset() {
    let temp_dir = tempfile::tempdir().unwrap();
    let gh_log = temp_dir.path().join("gh_log.txt");

    let mock_script = create_gh_mock_script(&gh_log);

    let _path_guard = create_mock_bin("gh", &temp_dir, &mock_script);

    let args = labels_reset::LabelsResetArgs { repo: Some("owner/repo".to_string()) };

    labels_reset::run(args).expect("reset should succeed");

    let log_content = fs::read_to_string(gh_log).unwrap();
    assert!(log_content.contains("label delete bugs"));
}
