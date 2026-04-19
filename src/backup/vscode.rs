//! VSCode backup implementation.

use std::path::{Path, PathBuf};

use crate::app::AppContext;
use crate::backup::vscode_port::VscodePort;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

const VSCODE_SETTINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Code", "User", "settings.json"];

pub fn execute(ctx: &AppContext, output_dir: &Path) -> Result<(), AppError> {
    let mut extensions = ctx.vscode.list_extensions()?;
    extensions.sort();
    extensions.dedup();

    let content = serialize_extensions(&extensions)?;
    let settings_source = current_settings_path(&ctx.home_dir);
    if !ctx.host_fs.exists(&settings_source) {
        return Err(AppError::Backup(format!(
            "VSCode settings file not found: {}",
            settings_source.display()
        )));
    }

    ctx.host_fs.create_dir_all(output_dir)?;

    let extensions_output = output_dir.join("vscode-extensions.json");
    ctx.host_fs.write(&extensions_output, content.as_bytes())?;
    let settings_output = output_dir.join("settings.json");
    ctx.host_fs.copy(&settings_source, &settings_output)?;

    println!("VSCode extensions list backed up to: {}", extensions_output.display());
    println!("VSCode settings backed up to: {}", settings_output.display());

    Ok(())
}

fn serialize_extensions(extensions: &[String]) -> Result<String, AppError> {
    let payload = serde_json::json!({ "extensions": extensions });
    serde_json::to_string_pretty(&payload)
        .map(|content| format!("{content}\n"))
        .map_err(|e| AppError::Backup(format!("failed to serialize extensions: {e}")))
}

fn current_settings_path(home_dir: &Path) -> PathBuf {
    VSCODE_SETTINGS_RELATIVE_PATH
        .iter()
        .fold(home_dir.to_path_buf(), |path, segment| path.join(segment))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn serialize_extensions_writes_pretty_json_with_trailing_newline() {
        let extensions =
            vec!["ms-python.python".to_string(), "rust-lang.rust-analyzer".to_string()];

        let content = serialize_extensions(&extensions).unwrap();

        assert_eq!(
            content,
            "{\n  \"extensions\": [\n    \"ms-python.python\",\n    \"rust-lang.rust-analyzer\"\n  ]\n}\n"
        );
    }

    #[test]
    fn current_settings_path_targets_vscode_user_settings() {
        let path = current_settings_path(Path::new("/Users/tester"));

        assert_eq!(
            path,
            PathBuf::from("/Users/tester/Library/Application Support/Code/User/settings.json")
        );
    }
}
