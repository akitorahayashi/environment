//! System settings backup implementation.

use std::borrow::Cow;
use std::path::{Path, PathBuf};

use serde::Deserialize;

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::ports::fs::FsPort;
use crate::domain::ports::macos_defaults::MacosDefaultsPort;

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

pub fn execute(
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
        let formatted = format_value(def, &raw_value)?;
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

fn format_value(def: &SettingDefinition, raw_value: &str) -> Result<String, AppError> {
    match def.type_name.to_lowercase().as_str() {
        "bool" => Ok(format_bool(raw_value, &def.default)),
        "int" => Ok(format_numeric(raw_value, &def.default, false)),
        "float" => Ok(format_numeric(raw_value, &def.default, true)),
        "string" => format_string(raw_value, &def.key, &def.default),
        _ => {
            let value = if raw_value.is_empty() {
                value_to_string(&def.default)
            } else {
                Cow::Borrowed(raw_value)
            };
            serde_json::to_string(&value).map_err(|e| {
                AppError::Backup(format!("failed to serialize value for key '{}': {e}", def.key))
            })
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

fn format_string(
    raw_value: &str,
    key: &str,
    default: &serde_yaml::Value,
) -> Result<String, AppError> {
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
    use serial_test::serial;

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
        assert_eq!(format_numeric("42.5", &serde_yaml::Value::Null, false), "42"); // float to int fallback
        assert_eq!(
            format_numeric("invalid", &serde_yaml::Value::String("invalid".to_string()), false),
            "invalid"
        );
    }

    #[test]
    #[serial]
    fn test_format_string() {
        #[allow(unused_unsafe)]
        unsafe {
            std::env::set_var("HOME", "/mock/home");
        }
        assert_eq!(format_string("hello", "key", &serde_yaml::Value::Null), "\"hello\"");
        assert_eq!(
            format_string("", "key", &serde_yaml::Value::String("default".to_string())),
            "\"default\""
        );

        let path = "/mock/home/file.txt";
        assert_eq!(format_string(path, "location", &serde_yaml::Value::Null), "\"$HOME/file.txt\"");
    }

    #[test]
    fn test_build_entry() {
        let def = SettingDefinition {
            key: "TestKey".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "string".to_string(),
            default: serde_yaml::Value::Null,
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
            default: serde_yaml::Value::Bool(false),
            comment: None,
        };
        assert_eq!(format_value(&bool_def, "1"), "true");

        let int_def = SettingDefinition {
            key: "int_key".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "int".to_string(),
            default: serde_yaml::Value::Null,
            comment: None,
        };
        assert_eq!(format_value(&int_def, "42"), "42");

        let default_def = SettingDefinition {
            key: "other_key".to_string(),
            domain: "TestDomain".to_string(),
            type_name: "dict".to_string(),
            default: serde_yaml::Value::String("default".to_string()),
            comment: None,
        };
        assert_eq!(format_value(&default_def, ""), "\"default\"");
        assert_eq!(
            format_value(&default_def, "{\"key\":\"value\"}"),
            "\"{\\\"key\\\":\\\"value\\\"}\""
        );
    }
}
