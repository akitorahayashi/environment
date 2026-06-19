use mev_vcs::gh;
use mev_vcs::testing::env_mock::{PathGuard, create_mock_bin};
use serial_test::serial;
use std::fs;

fn gh_mock_script(log_path: &std::path::Path) -> String {
    format!(
        "#!/bin/sh\necho \"$@\" >> \"{}\"\nif [ \"$1\" = \"label\" ] && [ \"$2\" = \"list\" ]; then\n    echo \"\"\nelse\n    exit 0\nfi",
        log_path.display()
    )
}

#[test]
#[serial(env_path)]
fn deploy_labels_creates_bundled_labels_on_explicit_repo() -> Result<(), Box<dyn std::error::Error>>
{
    let temp_dir = tempfile::tempdir()?;
    let gh_log = temp_dir.path().join("gh_log.txt");

    let mock_bin_dir = create_mock_bin("gh", &temp_dir, &gh_mock_script(&gh_log))?;
    #[allow(unused_unsafe)]
    let _path_guard = unsafe { PathGuard::new(&mock_bin_dir)? };

    gh::deploy_labels(Some("owner/repo"))?;

    let log_content = fs::read_to_string(gh_log)?;
    assert!(log_content.contains("label list"));
    assert!(log_content.contains("label create C-bugs"));
    Ok(())
}
