//! `backup` command orchestration — backup system settings or configurations.

use std::borrow::Cow;
use std::path::{Path, PathBuf};

use serde::Deserialize;

use crate::app::DependencyContainer;
use crate::domain::backup_target::{BackupTarget, validate_backup_target};
use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::ports::fs::FsPort;
use crate::domain::ports::macos_defaults::MacosDefaultsPort;
use crate::domain::ports::vscode::VscodePort;

const DEFAULT_DOMAIN: &str = "NSGlobalDomain";

#[derive(Debug, Deserialize)]
struct SettingDefinition {
    key: String,
    #[serde(default = "default_domain")]
    domain: String,
    #[serde(rename = "type")]
    type_name: String,
    #[serde(default)]
    default: serde_yaml::Value,
    #[serde(default)]
    comment: Option<String>,
}

fn default_domain() -> String {
    DEFAULT_DOMAIN.to_string()
}

enum DefinitionsDirResolution {
    Local(PathBuf),
    PackageDefault { resolved_dir: PathBuf, missing_local_dir: PathBuf },
}

/// Execute the `backup` command for a given target.
pub fn execute(ctx: &DependencyContainer, target_input: &str) -> Result<(), AppError> {
    let target = validate_backup_target(target_input)?;

    let local_config_dir = ctx.local_config_root.join(target.role()).join(target.subpath());

    println!("Running backup: {}", target.description());
    println!();

    match target {
        BackupTarget::System => {
            let definitions_dir = match resolve_definitions_dir(&local_config_dir, ctx, &target) {
                DefinitionsDirResolution::Local(path) => path,
                DefinitionsDirResolution::PackageDefault { resolved_dir, missing_local_dir } => {
                    println!(
                        "Local definitions not found at {}. Using package defaults.",
                        missing_local_dir.display()
                    );
                    resolved_dir
                }
            };
            let output_file = local_config_dir.join("system.yml");
            execute_system(ctx, &definitions_dir, &output_file)
        }
        BackupTarget::Vscode => {
            let output_file = local_config_dir.join("vscode-extensions.json");
            execute_vscode(ctx, &output_file)
        }
    }?;

    println!();
    println!("✓ Backup completed successfully!");

    Ok(())
}

// ---------------------------------------------------------------------------
// System defaults backup
// ---------------------------------------------------------------------------

fn execute_system(
    ctx: &DependencyContainer,
    definitions_dir: &Path,
    output_file: &Path,
) -> Result<(), AppError> {
    if !ctx.fs.exists(definitions_dir) {
        return Err(AppError::Backup(format!(
            "definitions directory not found: {}",
            definitions_dir.display()
        )));
    }

    let definitions = load_definitions(&ctx.fs, definitions_dir)?;
    if definitions.is_empty() {
        return Err(AppError::Backup(format!(
            "no setting definitions found in {}",
            definitions_dir.display()
        )));
    }

    let mut lines = vec!["---".to_string()];

    for def in &definitions {
        let raw_value = match ctx.macos_defaults.read_key(&def.domain, &def.key)? {
            Some(v) => v,
            None => value_to_string(&def.default).into_owned(),
        };
        let formatted = format_value(def, &raw_value);
        lines.extend(build_entry(def, &formatted));
    }

    lines.push(String::new());

    if let Some(parent) = output_file.parent() {
        ctx.fs.create_dir_all(parent)?;
    }
    ctx.fs.write(output_file, lines.join("\n").as_bytes())?;

    println!("Generated system defaults YAML: {}", output_file.display());
    Ok(())
}

fn load_definitions(fs: &dyn FsPort, dir: &Path) -> Result<Vec<SettingDefinition>, AppError> {
    let entries = fs.read_dir(dir)?;
    let mut paths: Vec<PathBuf> = entries
        .into_iter()
        .filter(|p| matches!(p.extension().and_then(|ext| ext.to_str()), Some("yml" | "yaml")))
        .collect();
    paths.sort();

    let mut definitions = Vec::new();
    for path in paths {
        let content = fs.read_to_string(&path)?;
        let items: Option<Vec<SettingDefinition>> = serde_yaml::from_str(&content)
            .map_err(|e| AppError::Backup(format!("invalid YAML in {}: {e}", path.display())))?;
        if let Some(items) = items {
            definitions.extend(items);
        }
    }

    Ok(definitions)
}

fn value_to_string(v: &serde_yaml::Value) -> Cow<'_, str> {
    match v {
        serde_yaml::Value::Bool(b) => Cow::Owned(b.to_string()),
        serde_yaml::Value::Number(n) => Cow::Owned(n.to_string()),
        serde_yaml::Value::String(s) => Cow::Borrowed(s.as_str()),
        serde_yaml::Value::Null => Cow::Borrowed(""),
        other => Cow::Owned(format!("{other:?}")),
    }
}

fn format_value(def: &SettingDefinition, raw_value: &str) -> String {
    match def.type_name.to_lowercase().as_str() {
        "bool" => format_bool(raw_value, &def.default),
        "int" => format_numeric(raw_value, &def.default, false),
        "float" => format_numeric(raw_value, &def.default, true),
        "string" => format_string(raw_value, &def.key, &def.default),
        _ => {
            let value = if raw_value.is_empty() {
                value_to_string(&def.default)
            } else {
                Cow::Borrowed(raw_value)
            };
            serde_json::to_string(&value).unwrap_or_else(|_| value.into_owned())
        }
    }
}

fn is_truthy(s: &str) -> Option<bool> {
    match s.trim().to_lowercase().as_str() {
        "1" | "true" | "yes" => Some(true),
        "0" | "false" | "no" => Some(false),
        _ => None,
    }
}

fn format_bool(raw_value: &str, default: &serde_yaml::Value) -> String {
    if let Some(b) = is_truthy(raw_value) {
        return b.to_string();
    }
    if let Some(b) = default.as_bool() {
        return b.to_string();
    }
    if let Some(s) = default.as_str()
        && let Some(b) = is_truthy(s)
    {
        return b.to_string();
    }
    "false".to_string()
}

fn format_numeric(raw_value: &str, default: &serde_yaml::Value, as_float: bool) -> String {
    let target = if raw_value.trim().is_empty() {
        value_to_string(default).into_owned()
    } else {
        raw_value.trim().to_string()
    };
    if as_float {
        target.parse::<f64>().map(|f| f.to_string()).unwrap_or(target)
    } else if let Ok(i) = target.parse::<i64>() {
        i.to_string()
    } else {
        target.parse::<f64>().map(|f| (f as i64).to_string()).unwrap_or(target)
    }
}

fn format_string(raw_value: &str, key: &str, default: &serde_yaml::Value) -> String {
    let mut value = if raw_value.is_empty() {
        match default {
            serde_yaml::Value::String(s) => Cow::Borrowed(s.as_str()),
            _ => Cow::Borrowed(""),
        }
    } else {
        Cow::Borrowed(raw_value)
    };

    if key == "location"
        && let Ok(home) = std::env::var("HOME")
        && value.starts_with(&home)
    {
        value = Cow::Owned(value.replacen(&home, "$HOME", 1));
    }

    serde_json::to_string(&value).unwrap_or_else(|_| value.into_owned())
}

fn build_entry(def: &SettingDefinition, value: &str) -> Vec<String> {
    let mut parts = vec![format!("key: \"{}\"", def.key)];
    if def.domain != DEFAULT_DOMAIN {
        parts.push(format!("domain: \"{}\"", def.domain));
    }
    parts.push(format!("type: \"{}\"", def.type_name));
    parts.push(format!("value: {value}"));

    let entry = format!("- {{ {} }}", parts.join(", "));

    let mut lines = Vec::new();
    if let Some(ref comment) = def.comment {
        let safe_comment = comment.replace(['\n', '\r'], " ");
        lines.push(format!("# {safe_comment}"));
    }
    lines.push(entry);
    lines
}

// ---------------------------------------------------------------------------
// VSCode extensions backup
// ---------------------------------------------------------------------------

fn execute_vscode(ctx: &DependencyContainer, output_file: &Path) -> Result<(), AppError> {
    let mut extensions = ctx.vscode.list_extensions()?;
    extensions.sort();
    extensions.dedup();

    let payload = serde_json::json!({ "extensions": extensions });
    let content = serde_json::to_string_pretty(&payload)
        .map_err(|e| AppError::Backup(format!("failed to serialize extensions: {e}")))?;

    if let Some(parent) = output_file.parent() {
        ctx.fs.create_dir_all(parent)?;
    }
    ctx.fs.write(output_file, format!("{content}\n").as_bytes())?;

    println!("VSCode extensions list backed up to: {}", output_file.display());
    Ok(())
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Resolve definitions directory with fallback from local to package defaults.
fn resolve_definitions_dir(
    local_config_dir: &Path,
    ctx: &DependencyContainer,
    target: &BackupTarget,
) -> DefinitionsDirResolution {
    let local_definitions = local_config_dir.join("definitions");
    if local_definitions.exists() {
        return DefinitionsDirResolution::Local(local_definitions);
    }

    let package_default_dir = ctx
        .ansible
        .role_config_dir(target.role())
        .map(|p| p.join(target.subpath()).join("definitions"))
        .unwrap_or_default();

    DefinitionsDirResolution::PackageDefault {
        resolved_dir: package_default_dir,
        missing_local_dir: local_definitions,
    }
}

pub fn list_targets() {
    println!("Available backup targets:");
    println!();
    for target in BackupTarget::all() {
        println!("  {:<8} - {}", target.name(), target.description());
    }
    println!();
    println!("Usage: mev backup <target>");
}
