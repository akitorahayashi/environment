//! System settings backup implementation.

use std::borrow::Cow;
use std::collections::{BTreeMap, HashSet};
use std::path::{Path, PathBuf};
use std::process::Command;

use serde::Deserialize;

use crate::app::AppContext;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

const DEFAULT_DOMAIN: &str = "NSGlobalDomain";

/// Keys that must be read with `defaults read -g <key>` instead of
/// `defaults read <domain> <key>` because macOS registers them
/// under the global domain regardless of the preference pane domain.
const SPECIAL_GLOBAL_KEYS: &[&str] = &[
    "com.apple.keyboard.fnState",
    "com.apple.trackpad.scaling",
    "com.apple.sound.beep.feedback",
    "com.apple.sound.beep.sound",
];

pub struct MacosDefaultsCli;

trait MacosDefaultsPort {
    fn read_key(&self, domain: &str, key: &str) -> Result<Option<String>, AppError>;
}

impl MacosDefaultsPort for MacosDefaultsCli {
    fn read_key(&self, domain: &str, key: &str) -> Result<Option<String>, AppError> {
        let output = if SPECIAL_GLOBAL_KEYS.contains(&key) {
            Command::new("defaults").args(["read", "-g", key]).output()
        } else {
            Command::new("defaults").args(["read", domain, key]).output()
        };

        match output {
            Ok(o) if o.status.success() => {
                Ok(Some(String::from_utf8_lossy(&o.stdout).trim().to_string()))
            }
            Ok(o) => {
                let stderr = String::from_utf8_lossy(&o.stderr);
                if stderr.contains("does not exist") {
                    Ok(None)
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
}

#[derive(Clone, Debug, Deserialize)]
struct SettingDefinition {
    key: String,
    #[serde(default = "default_domain")]
    domain: String,
    #[serde(rename = "type")]
    type_name: String,
    value: serde_yaml::Value,
    #[serde(default)]
    comment: Option<String>,
}

struct SourcedDefinition {
    definition: SettingDefinition,
    relative_path: PathBuf,
}

fn default_domain() -> String {
    DEFAULT_DOMAIN.to_string()
}

pub fn execute(
    ctx: &AppContext,
    package_definitions_dir: &Path,
    local_definitions_dir: &Path,
) -> Result<(), AppError> {
    if !ctx.host_fs.exists(package_definitions_dir) {
        return Err(AppError::Backup(format!(
            "package definitions directory not found: {}",
            package_definitions_dir.display()
        )));
    }

    let package_definitions = load_definitions(&ctx.host_fs, package_definitions_dir)?;
    if package_definitions.is_empty() {
        return Err(AppError::Backup(format!(
            "no setting definitions found in {}",
            package_definitions_dir.display()
        )));
    }
    let local_definitions = if ctx.host_fs.exists(local_definitions_dir) {
        load_definitions(&ctx.host_fs, local_definitions_dir)?
    } else {
        Vec::new()
    };
    let definitions = merge_definitions(package_definitions, local_definitions)?;

    let home_dir = ctx.home_dir.to_string_lossy();
    let mut files: BTreeMap<PathBuf, Vec<String>> = BTreeMap::new();

    for sourced in definitions.values() {
        let def = &sourced.definition;
        let raw_value = match ctx.macos_defaults.read_key(&def.domain, &def.key)? {
            Some(v) => v,
            None => {
                println!(
                    "Setting absent for domain='{}', key='{}'; retaining configured value.",
                    def.domain, def.key
                );
                value_to_string(&def.value).into_owned()
            }
        };
        let formatted = format_value(def, &raw_value, &home_dir)?;
        files
            .entry(sourced.relative_path.clone())
            .or_insert_with(|| vec!["---".to_string()])
            .extend(build_entry(def, &formatted));
    }

    let staging_dir = local_definitions_dir.with_file_name(".global.staging");
    if ctx.host_fs.exists(&staging_dir) {
        ctx.host_fs.remove_dir_all(&staging_dir)?;
    }
    ctx.host_fs.create_dir_all(&staging_dir)?;

    for (relative_path, mut lines) in files {
        lines.push(String::new());
        let output_file = staging_dir.join(relative_path);
        if let Some(parent) = output_file.parent() {
            ctx.host_fs.create_dir_all(parent)?;
        }
        ctx.host_fs.write(&output_file, lines.join("\n").as_bytes())?;
    }

    if ctx.host_fs.exists(local_definitions_dir) {
        ctx.host_fs.remove_dir_all(local_definitions_dir)?;
    }
    ctx.host_fs.rename(&staging_dir, local_definitions_dir)?;

    println!("Generated system definition snapshot: {}", local_definitions_dir.display());
    Ok(())
}

fn load_definitions(fs: &dyn FsPort, root: &Path) -> Result<Vec<SourcedDefinition>, AppError> {
    let mut paths: Vec<PathBuf> = fs
        .read_dir(root)?
        .into_iter()
        .filter(|path| matches!(path.extension().and_then(|ext| ext.to_str()), Some("yml")))
        .collect();
    paths.sort();

    let mut definitions = Vec::new();
    for path in paths {
        let content = fs.read_to_string(&path)?;
        let items: Option<Vec<SettingDefinition>> = serde_yaml::from_str(&content)
            .map_err(|e| AppError::Backup(format!("invalid YAML in {}: {e}", path.display())))?;
        if let Some(items) = items {
            let relative_path = path.strip_prefix(root).map_err(|e| {
                AppError::Backup(format!(
                    "failed to resolve definition path '{}': {e}",
                    path.display()
                ))
            })?;
            definitions.extend(items.into_iter().map(|definition| SourcedDefinition {
                definition,
                relative_path: relative_path.to_path_buf(),
            }));
        }
    }

    Ok(definitions)
}

fn merge_definitions(
    package: Vec<SourcedDefinition>,
    local: Vec<SourcedDefinition>,
) -> Result<BTreeMap<(String, String), SourcedDefinition>, AppError> {
    reject_duplicate_definitions(&package, "package")?;
    reject_duplicate_definitions(&local, "local")?;

    let mut effective = BTreeMap::new();
    for sourced in package.into_iter().chain(local) {
        let identity = (sourced.definition.domain.clone(), sourced.definition.key.clone());
        effective.insert(identity, sourced);
    }
    Ok(effective)
}

fn reject_duplicate_definitions(
    definitions: &[SourcedDefinition],
    layer: &str,
) -> Result<(), AppError> {
    let mut identities = HashSet::new();
    for sourced in definitions {
        let identity = (sourced.definition.domain.clone(), sourced.definition.key.clone());
        if !identities.insert(identity.clone()) {
            return Err(AppError::Backup(format!(
                "duplicate system definition in {layer} layer: domain='{}', key='{}'",
                identity.0, identity.1
            )));
        }
    }
    Ok(())
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

fn format_value(
    def: &SettingDefinition,
    raw_value: &str,
    home_dir: &str,
) -> Result<String, AppError> {
    match def.type_name.to_lowercase().as_str() {
        "bool" => Ok(format_bool(raw_value, &def.value)),
        "int" => Ok(format_numeric(raw_value, &def.value, false)),
        "float" => Ok(format_numeric(raw_value, &def.value, true)),
        "string" => format_string(raw_value, &def.key, &def.value, home_dir),
        _ => Err(AppError::Backup(format!(
            "unsupported type '{}' for domain='{}', key='{}'",
            def.type_name, def.domain, def.key
        ))),
    }
}

fn is_truthy(s: &str) -> Option<bool> {
    match s.trim().to_lowercase().as_str() {
        "1" | "true" | "yes" => Some(true),
        "0" | "false" | "no" => Some(false),
        _ => None,
    }
}

fn format_bool(raw_value: &str, configured: &serde_yaml::Value) -> String {
    if let Some(b) = is_truthy(raw_value) {
        return b.to_string();
    }
    if let Some(b) = configured.as_bool() {
        return b.to_string();
    }
    if let Some(s) = configured.as_str()
        && let Some(b) = is_truthy(s)
    {
        return b.to_string();
    }
    "false".to_string()
}

fn format_numeric(raw_value: &str, configured: &serde_yaml::Value, as_float: bool) -> String {
    let value_str = if raw_value.trim().is_empty() {
        value_to_string(configured).into_owned()
    } else {
        raw_value.trim().to_string()
    };
    if as_float {
        value_str.parse::<f64>().map(|f| f.to_string()).unwrap_or(value_str)
    } else if let Ok(i) = value_str.parse::<i64>() {
        i.to_string()
    } else {
        value_str.parse::<f64>().map(|f| (f as i64).to_string()).unwrap_or(value_str)
    }
}

fn format_string(
    raw_value: &str,
    key: &str,
    configured: &serde_yaml::Value,
    home_dir: &str,
) -> Result<String, AppError> {
    let mut value = if raw_value.is_empty() {
        match configured {
            serde_yaml::Value::String(s) => Cow::Borrowed(s.as_str()),
            _ => Cow::Borrowed(""),
        }
    } else {
        Cow::Borrowed(raw_value)
    };

    if key == "location" && !home_dir.is_empty() && value.starts_with(home_dir) {
        let suffix = &value[home_dir.len()..];
        if suffix.is_empty() || suffix.starts_with('/') {
            value = Cow::Owned(format!("$HOME{suffix}"));
        }
    }

    serde_json::to_string(&value).map_err(|e| {
        AppError::Backup(format!("failed to serialize string value for key '{key}': {e}"))
    })
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_value_to_string() {
        assert_eq!(value_to_string(&serde_yaml::Value::Bool(true)), "true");
        assert_eq!(value_to_string(&serde_yaml::Value::Number(serde_yaml::Number::from(42))), "42");
        assert_eq!(value_to_string(&serde_yaml::Value::String("hello".to_string())), "hello");
        assert_eq!(value_to_string(&serde_yaml::Value::Null), "");
    }

    #[test]
    fn test_is_truthy() {
        assert_eq!(is_truthy("1"), Some(true));
        assert_eq!(is_truthy("true"), Some(true));
        assert_eq!(is_truthy("yes"), Some(true));
        assert_eq!(is_truthy("0"), Some(false));
        assert_eq!(is_truthy("false"), Some(false));
        assert_eq!(is_truthy("no"), Some(false));
        assert_eq!(is_truthy("other"), None);
    }

    #[test]
    fn test_format_bool() {
        assert_eq!(format_bool("1", &serde_yaml::Value::Bool(false)), "true");
        assert_eq!(format_bool("invalid", &serde_yaml::Value::Bool(true)), "true");
        assert_eq!(format_bool("invalid", &serde_yaml::Value::String("true".to_string())), "true");
        assert_eq!(format_bool("invalid", &serde_yaml::Value::Null), "false");
    }

    #[test]
    fn test_format_numeric() {
        assert_eq!(format_numeric("42", &serde_yaml::Value::Null, false), "42");
        assert_eq!(
            format_numeric("", &serde_yaml::Value::Number(serde_yaml::Number::from(42)), false),
            "42"
        );
        assert_eq!(format_numeric("42.5", &serde_yaml::Value::Null, true), "42.5");
        assert_eq!(format_numeric("42.5", &serde_yaml::Value::Null, false), "42");
        assert_eq!(
            format_numeric("invalid", &serde_yaml::Value::String("invalid".to_string()), false),
            "invalid"
        );
    }

    #[test]
    fn test_format_string() {
        assert_eq!(
            format_string("hello", "key", &serde_yaml::Value::Null, "/mock/home")
                .expect("string formatting should succeed"),
            "\"hello\""
        );
        assert_eq!(
            format_string(
                "",
                "key",
                &serde_yaml::Value::String("configured".to_string()),
                "/mock/home"
            )
            .expect("configured string formatting should succeed"),
            "\"configured\""
        );

        let path = "/mock/home/file.txt";
        assert_eq!(
            format_string(path, "location", &serde_yaml::Value::Null, "/mock/home")
                .expect("location string formatting should succeed"),
            "\"$HOME/file.txt\""
        );

        let path = "/mock/home_backup/file.txt";
        assert_eq!(
            format_string(path, "location", &serde_yaml::Value::Null, "/mock/home")
                .expect("location string formatting should succeed"),
            "\"/mock/home_backup/file.txt\""
        );
    }

    #[test]
    fn test_build_entry() {
        let def = SettingDefinition {
            key: "TestKey".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "string".to_string(),
            value: serde_yaml::Value::Null,
            comment: Some("Test comment\nnewline".to_string()),
        };
        let lines = build_entry(&def, "\"value\"");
        assert_eq!(lines.len(), 2);
        assert_eq!(lines[0], "# Test comment newline");
        assert_eq!(
            lines[1],
            "- { key: \"TestKey\", domain: \"TestDomain\", type: \"string\", value: \"value\" }"
        );
    }

    #[test]
    fn test_format_value() {
        let bool_def = SettingDefinition {
            key: "bool_key".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "bool".to_string(),
            value: serde_yaml::Value::Bool(false),
            comment: None,
        };
        assert_eq!(
            format_value(&bool_def, "1", "/mock/home").expect("bool formatting should succeed"),
            "true"
        );

        let int_def = SettingDefinition {
            key: "int_key".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "int".to_string(),
            value: serde_yaml::Value::Null,
            comment: None,
        };
        assert_eq!(
            format_value(&int_def, "42", "/mock/home").expect("int formatting should succeed"),
            "42"
        );

        let configured_def = SettingDefinition {
            key: "other_key".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "dict".to_string(),
            value: serde_yaml::Value::String("configured".to_string()),
            comment: None,
        };
        assert!(format_value(&configured_def, "", "/mock/home").is_err());
    }
}
