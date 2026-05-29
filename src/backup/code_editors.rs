//! Code editor backup implementation.

use std::path::{Path, PathBuf};

use crate::app::AppContext;
use crate::backup::component::BackupComponent;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

const VSCODE_COMMAND_CANDIDATES: &[&str] = &[
    "code",
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
    "code-insiders",
];
const ANTIGRAVITY_IDE_COMMAND_CANDIDATES: &[&str] = &[
    "agy-ide",
    "antigravity-ide",
    "/Applications/Antigravity IDE.app/Contents/Resources/app/bin/antigravity-ide",
];

const VSCODE_SETTINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Code", "User", "settings.json"];
const VSCODE_KEYBINDINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Code", "User", "keybindings.json"];

const ANTIGRAVITY_IDE_SETTINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Antigravity IDE", "User", "settings.json"];
const ANTIGRAVITY_IDE_KEYBINDINGS_RELATIVE_PATH: &[&str] =
    &["Library", "Application Support", "Antigravity IDE", "User", "keybindings.json"];

struct EditorSpec {
    display_name: &'static str,
    command_candidates: &'static [&'static str],
    settings_relative_path: &'static [&'static str],
    keybindings_relative_path: &'static [&'static str],
    filter_create_instance_logs: bool,
}

pub struct CodeEditorCli;

impl CodeEditorCli {
    fn list_extensions(&self, spec: &EditorSpec) -> Result<Vec<String>, AppError> {
        let command = detect_command(spec.command_candidates)?;
        let output =
            std::process::Command::new(&command).arg("--list-extensions").output().map_err(
                |e| AppError::Backup(format!("failed to run '{command} --list-extensions': {e}")),
            )?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(AppError::Backup(format!(
                "failed to list {} extensions: {}",
                spec.display_name,
                stderr.trim()
            )));
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout
            .lines()
            .map(str::trim)
            .filter(|line| {
                !line.is_empty()
                    && (!spec.filter_create_instance_logs || !line.starts_with("[createInstance]"))
            })
            .map(str::to_string)
            .collect())
    }
}

pub fn execute(
    ctx: &AppContext,
    component: BackupComponent,
    output_dir: &Path,
) -> Result<(), AppError> {
    let spec = editor_spec(component)?;

    let mut extensions = ctx.code_editor_extensions.list_extensions(&spec)?;
    extensions.sort();
    extensions.dedup();

    let content = serialize_extensions(&extensions)?;
    let settings_source = current_file_path(&ctx.home_dir, spec.settings_relative_path);
    let keybindings_source = current_file_path(&ctx.home_dir, spec.keybindings_relative_path);

    ctx.host_fs.create_dir_all(output_dir)?;

    let extensions_output = output_dir.join("extensions.json");
    ctx.host_fs.write(&extensions_output, content.as_bytes())?;
    backup_user_file(
        ctx,
        &settings_source,
        output_dir,
        "settings.json",
        &format!("{} settings", spec.display_name),
    )?;
    backup_user_file(
        ctx,
        &keybindings_source,
        output_dir,
        "keybindings.json",
        &format!("{} keybindings", spec.display_name),
    )?;

    println!("{} extensions list backed up to: {}", spec.display_name, extensions_output.display());

    Ok(())
}

fn editor_spec(component: BackupComponent) -> Result<EditorSpec, AppError> {
    match component {
        BackupComponent::Vscode => Ok(EditorSpec {
            display_name: "VS Code",
            command_candidates: VSCODE_COMMAND_CANDIDATES,
            settings_relative_path: VSCODE_SETTINGS_RELATIVE_PATH,
            keybindings_relative_path: VSCODE_KEYBINDINGS_RELATIVE_PATH,
            filter_create_instance_logs: false,
        }),
        BackupComponent::AntigravityIde => Ok(EditorSpec {
            display_name: "Antigravity IDE",
            command_candidates: ANTIGRAVITY_IDE_COMMAND_CANDIDATES,
            settings_relative_path: ANTIGRAVITY_IDE_SETTINGS_RELATIVE_PATH,
            keybindings_relative_path: ANTIGRAVITY_IDE_KEYBINDINGS_RELATIVE_PATH,
            filter_create_instance_logs: true,
        }),
        other => Err(AppError::Backup(format!(
            "editor backup is not supported for component: {}",
            other.name()
        ))),
    }
}

fn detect_command(candidates: &[&str]) -> Result<String, AppError> {
    for candidate in candidates {
        if let Ok(path) = which::which(candidate) {
            return Ok(path.to_string_lossy().into_owned());
        }
    }

    Err(AppError::Backup("editor command not found in PATH or default locations".to_string()))
}

fn serialize_extensions(extensions: &[String]) -> Result<String, AppError> {
    let payload = serde_json::json!({ "extensions": extensions });
    serde_json::to_string_pretty(&payload)
        .map(|content| format!("{content}\n"))
        .map_err(|e| AppError::Backup(format!("failed to serialize extensions: {e}")))
}

fn current_file_path(home_dir: &Path, relative_path: &[&str]) -> PathBuf {
    relative_path.iter().fold(home_dir.to_path_buf(), |path, segment| path.join(segment))
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

fn same_file(fs: &dyn FsPort, left: &Path, right: &Path) -> Result<bool, AppError> {
    if !fs.exists(left) || !fs.exists(right) {
        return Ok(false);
    }

    Ok(fs.canonicalize(left)? == fs.canonicalize(right)?)
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
    fn current_file_path_targets_vscode_user_settings() {
        let path = current_file_path(Path::new("/Users/tester"), VSCODE_SETTINGS_RELATIVE_PATH);
        assert_eq!(
            path,
            PathBuf::from("/Users/tester/Library/Application Support/Code/User/settings.json")
        );
    }

    #[test]
    fn current_file_path_targets_antigravity_ide_user_keybindings() {
        let path = current_file_path(
            Path::new("/Users/tester"),
            ANTIGRAVITY_IDE_KEYBINDINGS_RELATIVE_PATH,
        );
        assert_eq!(
            path,
            PathBuf::from(
                "/Users/tester/Library/Application Support/Antigravity IDE/User/keybindings.json"
            )
        );
    }
}
