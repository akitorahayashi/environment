//! Shell helper generators.

use std::fs;

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

fn gen_gemini_aliases() -> Result<(), Box<dyn std::error::Error>> {
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

    for (model_key, model_name) in &models {
        for (opts_key, opts_value) in &options {
            let separator = if opts_key.is_empty() { "" } else { "-" };
            let alias_name = format!("gm-{model_key}{separator}{opts_key}");
            let mut cmd_parts = format!("gemini -m {model_name}");
            if !opts_value.is_empty() {
                cmd_parts.push(' ');
                cmd_parts.push_str(opts_value);
            }
            println!("alias {alias_name}=\"{cmd_parts}\"");
        }
    }
    Ok(())
}

fn gen_vscode_workspace(paths: Vec<String>) -> Result<(), Box<dyn std::error::Error>> {
    let folders: Vec<serde_json::Value> =
        paths.iter().map(|p| serde_json::json!({ "path": p })).collect();

    let workspace = serde_json::json!({ "folders": folders });

    let cwd = std::env::current_dir()?;
    let output_path = cwd.join("workspace.code-workspace");
    let content = serde_json::to_string_pretty(&workspace)?;
    fs::write(&output_path, content)?;
    println!("✅ Workspace file created: {}", output_path.file_name().unwrap().to_string_lossy());
    Ok(())
}
