//! Shell helper generators.

use std::fs;
use std::path::Path;

use clap::Subcommand;

#[derive(Subcommand)]
pub enum ShellCommand {
    /// Generate Gemini model aliases for shell initialization.
    GenGeminiAliases,

    /// Generate a VSCode .code-workspace file from given paths.
    GenVscodeWorkspace {
        /// Paths to include in the workspace.
        paths: Vec<String>,
    },
}

pub fn run(cmd: ShellCommand) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        ShellCommand::GenGeminiAliases => gen_gemini_aliases(),
        ShellCommand::GenVscodeWorkspace { paths } => gen_vscode_workspace(paths),
    }
}

fn build_gemini_aliases() -> Vec<String> {
    let models: Vec<(&str, &str)> = vec![
        ("pr", "gemini-3.1-pro-preview"),
        ("fl", "gemini-3-flash-preview"),
        ("lt", "gemini-2.5-flash-lite"),
        ("i", "gemini-2.5-flash-image-preview"),
        ("il", "gemini-2.5-flash-image-live-preview"),
    ];

    let options: Vec<(&str, &str)> = vec![
        ("", ""),
        ("y", "-y"),
        ("p", "-p"),
        ("ap", "-a -p"),
        ("yp", "-y -p"),
        ("yap", "-y -a -p"),
    ];

    let mut aliases = Vec::new();
    for (model_key, model_name) in &models {
        for (opts_key, opts_value) in &options {
            let separator = if opts_key.is_empty() { "" } else { "-" };
            let alias_name = format!("gm-{model_key}{separator}{opts_key}");
            let mut cmd_parts = format!("gemini -m {model_name}");
            if !opts_value.is_empty() {
                cmd_parts.push(' ');
                cmd_parts.push_str(opts_value);
            }
            aliases.push(format!("alias {alias_name}=\"{cmd_parts}\""));
        }
    }
    aliases
}

fn gen_gemini_aliases() -> Result<(), Box<dyn std::error::Error>> {
    for line in build_gemini_aliases() {
        println!("{line}");
    }
    Ok(())
}

fn gen_vscode_workspace(paths: Vec<String>) -> Result<(), Box<dyn std::error::Error>> {
    let cwd = std::env::current_dir()?;
    gen_vscode_workspace_in_dir(paths, &cwd)
}

fn gen_vscode_workspace_in_dir(
    paths: Vec<String>,
    output_dir: &Path,
) -> Result<(), Box<dyn std::error::Error>> {
    let folders: Vec<serde_json::Value> =
        paths.iter().map(|p| serde_json::json!({ "path": p })).collect();

    let workspace = serde_json::json!({ "folders": folders });

    let output_path = output_dir.join("workspace.code-workspace");
    let content = serde_json::to_string_pretty(&workspace)?;
    fs::write(&output_path, content)?;
    println!(
        "✅ Workspace file created: {}",
        output_path
            .file_name()
            .ok_or_else(|| format!(
                "Failed to extract file name from path: {}",
                output_path.display()
            ))?
            .to_string_lossy()
    );
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn gen_gemini_aliases_produces_30_aliases() {
        let aliases = build_gemini_aliases();
        assert_eq!(aliases.len(), 30, "expected 30 aliases (5 models × 6 options)");
    }

    #[test]
    fn gen_gemini_aliases_all_start_with_alias_prefix() {
        for line in build_gemini_aliases() {
            assert!(line.starts_with("alias "), "unexpected line: {line}");
        }
    }

    #[test]
    fn gen_gemini_aliases_contains_expected_entries() {
        let aliases = build_gemini_aliases();
        assert!(aliases.contains(&r#"alias gm-pr="gemini -m gemini-3.1-pro-preview""#.to_string()));
        assert!(aliases.contains(&r#"alias gm-fl="gemini -m gemini-3-flash-preview""#.to_string()));
        assert!(
            aliases.contains(&r#"alias gm-pr-y="gemini -m gemini-3.1-pro-preview -y""#.to_string())
        );
        assert!(
            aliases.contains(
                &r#"alias gm-fl-ap="gemini -m gemini-3-flash-preview -a -p""#.to_string()
            )
        );
    }

    #[test]
    fn gen_vscode_workspace_creates_file_with_expected_folders()
    -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempfile::tempdir()?;
        let result = gen_vscode_workspace_in_dir(
            vec!["../path1".to_string(), "/abs/path2".to_string()],
            dir.path(),
        );
        result?;

        let ws_file = dir.path().join("workspace.code-workspace");
        assert!(ws_file.exists());

        let content: serde_json::Value = serde_json::from_str(&std::fs::read_to_string(&ws_file)?)?;
        let folders = content["folders"].as_array().ok_or("folders is not an array")?;
        assert_eq!(folders.len(), 2);
        assert_eq!(folders[0]["path"], "../path1");
        assert_eq!(folders[1]["path"], "/abs/path2");
        Ok(())
    }
}
