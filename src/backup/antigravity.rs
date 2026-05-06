//! Antigravity backup implementation.

use std::path::{Path, PathBuf};

use crate::app::AppContext;
use crate::backup::antigravity_port::AntigravityPort;
use crate::backup::file_identity::same_file;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

const ANTIGRAVITY_SETTINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Antigravity", "User", "settings.json"];
const ANTIGRAVITY_KEYBINDINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Antigravity", "User", "keybindings.json"];

pub fn execute(ctx: &AppContext, output_dir: &Path) -> Result<(), AppError> {
    let mut extensions = ctx.antigravity.list_extensions()?;
    extensions.sort();
    extensions.dedup();

    let content = serialize_extensions(&extensions)?;
    let settings_source = current_settings_path(&ctx.home_dir);
    let keybindings_source = current_keybindings_path(&ctx.home_dir);

    ctx.host_fs.create_dir_all(output_dir)?;

    let extensions_output = output_dir.join("extensions.json");
    ctx.host_fs.write(&extensions_output, content.as_bytes())?;
    backup_user_file(ctx, &settings_source, output_dir, "settings.json", "Antigravity settings")?;
    backup_user_file(
        ctx,
        &keybindings_source,
        output_dir,
        "keybindings.json",
        "Antigravity keybindings",
    )?;

    println!("Antigravity extensions list backed up to: {}", extensions_output.display());

    Ok(())
}

fn serialize_extensions(extensions: &[String]) -> Result<String, AppError> {
    let payload = serde_json::json!({ "extensions": extensions });
    serde_json::to_string_pretty(&payload)
        .map(|content| format!("{content}\n"))
        .map_err(|e| AppError::Backup(format!("failed to serialize extensions: {e}")))
}

fn current_settings_path(home_dir: &Path) -> PathBuf {
    ANTIGRAVITY_SETTINGS_RELATIVE_PATH
        .iter()
        .fold(home_dir.to_path_buf(), |path, segment| path.join(segment))
}

fn current_keybindings_path(home_dir: &Path) -> PathBuf {
    ANTIGRAVITY_KEYBINDINGS_RELATIVE_PATH
        .iter()
        .fold(home_dir.to_path_buf(), |path, segment| path.join(segment))
}

fn backup_user_file(
    ctx: &AppContext,
    source: &Path,
    output_dir: &Path,
    file_name: &str,
    description: &str,
) -> Result<(), AppError> {
    if !ctx.host_fs.exists(source) {
        return Err(AppError::Backup(format!(
            "{description} file not found: {}",
            source.display()
        )));
    }

    let output = output_dir.join(file_name);
    if same_file(&ctx.host_fs, source, &output)? {
        println!("{description} already managed at: {}", output.display());
    } else {
        ctx.host_fs.copy(source, &output)?;
        println!("{description} backed up to: {}", output.display());
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn serialize_extensions_writes_pretty_json_with_trailing_newline() {
        let extensions =
            vec!["mushan.vscode-paste-image".to_string(), "tomoki1207.pdf".to_string()];

        let content = serialize_extensions(&extensions).unwrap();

        assert_eq!(
            content,
            "{\n  \"extensions\": [\n    \"mushan.vscode-paste-image\",\n    \"tomoki1207.pdf\"\n  ]\n}\n"
        );
    }

    #[test]
    fn current_settings_path_targets_antigravity_user_settings() {
        let path = current_settings_path(Path::new("/Users/tester"));

        assert_eq!(
            path,
            PathBuf::from(
                "/Users/tester/Library/Application Support/Antigravity/User/settings.json"
            )
        );
    }

    #[test]
    fn current_keybindings_path_targets_antigravity_user_keybindings() {
        let path = current_keybindings_path(Path::new("/Users/tester"));

        assert_eq!(
            path,
            PathBuf::from(
                "/Users/tester/Library/Application Support/Antigravity/User/keybindings.json"
            )
        );
    }
}
