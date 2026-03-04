//! Backup macOS `defaults` values into automation-friendly YAML format.
//!
//! Reads YAML definition files from a definitions directory, queries each
//! setting via `defaults read`, formats the value according to declared type,
//! and writes a consolidated YAML output file.

use std::path::Path;
use std::process::Command;

use serde::Deserialize;

use crate::domain::error::AppError;

const DEFAULT_DOMAIN: &str = "NSGlobalDomain";

/// Keys that must be read with `defaults read -g <key>` instead of
/// `defaults read <domain> <key>`.
const SPECIAL_GLOBAL_KEYS: &[&str] = &[
    "com.apple.keyboard.fnState",
    "com.apple.trackpad.scaling",
    "com.apple.sound.beep.feedback",
    "com.apple.sound.beep.sound",
];

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

/// Execute system defaults backup.
///
/// Reads definition files from `definitions_dir`, queries macOS `defaults`,
/// and writes formatted YAML to `output_file`.
pub fn execute(definitions_dir: &Path, output_file: &Path) -> Result<(), AppError> {
    if !definitions_dir.exists() {
        return Err(AppError::Backup(format!(
            "definitions directory not found: {}",
            definitions_dir.display()
        )));
    }

    let definitions = load_definitions(definitions_dir)?;
    if definitions.is_empty() {
        return Err(AppError::Backup(format!(
            "no setting definitions found in {}",
            definitions_dir.display()
        )));
    }
    let mut lines = vec!["---".to_string()];

    for def in &definitions {
        let raw_value = read_defaults(&def.domain, &def.key, &def.default)?;
        let formatted = format_value(def, &raw_value);
        lines.extend(build_entry(def, &formatted));
    }

    lines.push(String::new());

    if let Some(parent) = output_file.parent() {
        std::fs::create_dir_all(parent)?;
    }
    std::fs::write(output_file, lines.join("\n"))?;

    println!("Generated system defaults YAML: {}", output_file.display());
    Ok(())
}

fn load_definitions(dir: &Path) -> Result<Vec<SettingDefinition>, AppError> {
    let mut paths = Vec::new();
    for entry in std::fs::read_dir(dir)? {
        let path = entry
            .map_err(|e| {
                AppError::Backup(format!("failed to read entry in {}: {e}", dir.display()))
            })?
            .path();
        if path.extension().and_then(|ext| ext.to_str()) == Some("yml") {
            paths.push(path);
        }
    }
    paths.sort();

    let mut definitions = Vec::new();
    for path in paths {
        let content = std::fs::read_to_string(&path)?;
        let items: Option<Vec<SettingDefinition>> = serde_yaml::from_str(&content)
            .map_err(|e| AppError::Backup(format!("invalid YAML in {}: {e}", path.display())))?;
        if let Some(items) = items {
            definitions.extend(items);
        }
    }

    Ok(definitions)
}

fn read_defaults(domain: &str, key: &str, default: &serde_yaml::Value) -> Result<String, AppError> {
    let output = if SPECIAL_GLOBAL_KEYS.contains(&key) {
        Command::new("defaults").args(["read", "-g", key]).output()
    } else {
        Command::new("defaults").args(["read", domain, key]).output()
    };

    match output {
        Ok(o) if o.status.success() => Ok(String::from_utf8_lossy(&o.stdout).trim().to_string()),
        Ok(o) => {
            let stderr = String::from_utf8_lossy(&o.stderr);
            if stderr.contains("does not exist") {
                Ok(value_to_string(default))
            } else {
                Err(AppError::Backup(format!(
                    "defaults read failed for domain='{domain}', key='{key}': {}",
                    stderr.trim()
                )))
            }
        }
        Err(e) => Err(AppError::Backup(format!(
            "failed to execute defaults for domain='{domain}', key='{key}': {e}"
        ))),
    }
}

fn value_to_string(v: &serde_yaml::Value) -> String {
    match v {
        serde_yaml::Value::Bool(b) => b.to_string(),
        serde_yaml::Value::Number(n) => n.to_string(),
        serde_yaml::Value::String(s) => s.clone(),
        serde_yaml::Value::Null => String::new(),
        other => format!("{other:?}"),
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
                raw_value.to_string()
            };
            serde_json::to_string(&value).unwrap_or(value)
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
        value_to_string(default)
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
            serde_yaml::Value::String(s) => s.clone(),
            _ => String::new(),
        }
    } else {
        raw_value.to_string()
    };

    if key == "location"
        && let Ok(home) = std::env::var("HOME")
        && value.starts_with(&home)
    {
        value = value.replacen(&home, "$HOME", 1);
    }

    serde_json::to_string(&value).unwrap_or(value)
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
