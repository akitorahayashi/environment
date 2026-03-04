//! Aider integration helpers.

use std::env;
use std::process::Command;

use clap::Subcommand;

const MODEL_ENV: &str = "AIDER_OLLAMA_MODEL";

#[derive(Subcommand)]
pub enum AiderCommand {
    /// Invoke aider with curated defaults.
    Run {
        /// Add a directory to the aider context.
        #[arg(short = 'd', long = "dir")]
        directories: Vec<String>,

        /// Add files by extension (recursively).
        #[arg(short = 'e', long = "ext")]
        extensions: Vec<String>,

        /// Add specific files to the aider context.
        #[arg(short = 'f', long = "files")]
        files: Vec<String>,

        /// Automatically accept aider suggestions.
        #[arg(short = 'y', long = "yes")]
        yolo: bool,

        /// Send a one-off message to aider.
        #[arg(short = 'm', long = "message")]
        message: Option<String>,

        /// Additional files.
        #[arg(trailing_var_arg = true)]
        targets: Vec<String>,
    },

    /// Set the default Ollama model for aider (eval-friendly output).
    SetModel {
        /// Ollama model name.
        model: Option<String>,
    },

    /// Unset the configured Ollama model (eval-friendly output).
    UnsetModel,

    /// List available Ollama models.
    ListModels,
}

pub fn run(cmd: AiderCommand) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        AiderCommand::Run { directories, extensions, files, yolo, message, targets } => {
            run_aider(directories, extensions, files, yolo, message, targets)
        }
        AiderCommand::SetModel { model } => set_model(model),
        AiderCommand::UnsetModel => unset_model(),
        AiderCommand::ListModels => list_models(),
    }
}

fn collect_extension_matches(extensions: &[String]) -> Vec<String> {
    let cwd = match env::current_dir() {
        Ok(d) => d,
        Err(_) => return Vec::new(),
    };
    let mut results = Vec::new();
    for ext in extensions {
        let normalized = ext.trim_start_matches('.');
        if normalized.is_empty() {
            continue;
        }
        let pattern = format!("**/*.{normalized}");
        if let Ok(entries) = glob::glob(&pattern) {
            let mut matched: Vec<String> = entries
                .filter_map(|e| e.ok())
                .filter(|p| p.is_file())
                .map(|p| p.strip_prefix(&cwd).unwrap_or(p.as_path()).to_string_lossy().into_owned())
                .collect();
            matched.sort();
            results.extend(matched);
        }
    }
    results
}

fn run_aider(
    directories: Vec<String>,
    extensions: Vec<String>,
    files: Vec<String>,
    yolo: bool,
    message: Option<String>,
    targets: Vec<String>,
) -> Result<(), Box<dyn std::error::Error>> {
    let model = env::var(MODEL_ENV).ok().filter(|v| !v.is_empty());
    let Some(model) = model else {
        eprintln!(
            "Error: {MODEL_ENV} environment variable is not set. \
             Use `ai-st <model_name>` to set it."
        );
        std::process::exit(1);
    };

    let provider_model = if model.contains('/') { model } else { format!("ollama/{model}") };

    let mut command = Command::new("aider");
    command.arg("--model").arg(provider_model).arg("--no-auto-commit").arg("--no-gitignore");

    if yolo {
        command.arg("--yes");
    }

    if let Some(msg) = message {
        command.arg("--message").arg(msg);
    }

    let mut all_targets: Vec<String> = Vec::new();
    all_targets.extend(directories);
    all_targets.extend(collect_extension_matches(&extensions));
    all_targets.extend(files);
    all_targets.extend(targets);
    command.args(all_targets);

    let status = command.status();

    match status {
        Ok(s) => std::process::exit(s.code().unwrap_or(1)),
        Err(e) => {
            eprintln!("Error: failed to execute \"aider\": {e}");
            std::process::exit(1);
        }
    }
}

fn set_model(model: Option<String>) -> Result<(), Box<dyn std::error::Error>> {
    let Some(model) = model else {
        let current = env::var(MODEL_ENV).unwrap_or_else(|_| "not set".into());
        eprintln!("Usage: set-model <model_name>");
        eprintln!("Current {MODEL_ENV}: {current}");
        std::process::exit(1);
    };

    let quoted = shell_quote(&model);
    println!("export {MODEL_ENV}={quoted}");
    println!("echo '✅ Set {MODEL_ENV} to: '{quoted}");
    Ok(())
}

fn unset_model() -> Result<(), Box<dyn std::error::Error>> {
    if env::var(MODEL_ENV).is_ok() {
        println!("unset {MODEL_ENV}");
        println!("echo \"✅ Unset {MODEL_ENV}\"");
    } else {
        println!("echo \"{MODEL_ENV} is already not set\"");
    }
    Ok(())
}

fn list_models() -> Result<(), Box<dyn std::error::Error>> {
    let ollama = which::which("ollama");
    if ollama.is_err() {
        eprintln!("Ollama is not installed");
        std::process::exit(1);
    }

    let output = Command::new("ollama").arg("list").output()?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr);
        eprintln!("{}", stderr.trim_end());
        std::process::exit(output.status.code().unwrap_or(1));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    let mut models: Vec<String> = Vec::new();
    for (idx, line) in stdout.lines().enumerate() {
        if idx == 0 && line.to_lowercase().starts_with("name") {
            continue;
        }
        if let Some(name) = line.split_whitespace().next() {
            models.push(name.to_string());
        }
    }

    println!("Available Ollama models for aider:");
    for name in &models {
        println!("  {name}");
    }
    println!();
    println!("Usage: ai-st <model> && ai [files...]");
    println!("Example: ai-st llama3.2 && ai main.py");
    println!();
    let current = env::var(MODEL_ENV).unwrap_or_else(|_| "not set".into());
    println!("Current {MODEL_ENV}: {current}");
    Ok(())
}

/// Simple POSIX-style shell quoting.
fn shell_quote(s: &str) -> String {
    if s.is_empty() {
        return "''".to_string();
    }
    if s.chars().all(|c| c.is_ascii_alphanumeric() || "._-/".contains(c)) {
        return s.to_string();
    }
    format!("'{}'", s.replace('\'', "'\"'\"'"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serial_test::serial;

    fn restore_model_env(original: Option<String>) {
        match original {
            Some(value) => unsafe {
                env::set_var(MODEL_ENV, value);
            },
            None => unsafe {
                env::remove_var(MODEL_ENV);
            },
        }
    }

    #[test]
    fn shell_quote_passes_through_safe_strings() {
        assert_eq!(shell_quote("llama3.2"), "llama3.2");
        assert_eq!(shell_quote("model-name_v1"), "model-name_v1");
    }

    #[test]
    fn shell_quote_wraps_strings_with_special_chars() {
        let result = shell_quote("my model");
        assert!(result.starts_with('\''));
    }

    #[test]
    fn shell_quote_empty_string() {
        assert_eq!(shell_quote(""), "''");
    }

    #[test]
    fn set_model_with_valid_model_succeeds() {
        let result = set_model(Some("llama3.2".to_string()));
        assert!(result.is_ok());
    }

    #[test]
    #[serial]
    fn unset_model_when_env_not_set_succeeds() {
        let original = env::var(MODEL_ENV).ok();
        unsafe {
            env::remove_var(MODEL_ENV);
        }
        let result = unset_model();
        restore_model_env(original);
        assert!(result.is_ok());
    }

    #[test]
    #[serial]
    fn unset_model_when_env_set_succeeds() {
        let original = env::var(MODEL_ENV).ok();
        unsafe {
            env::set_var(MODEL_ENV, "test-model");
        }
        let result = unset_model();
        restore_model_env(original);
        assert!(result.is_ok());
    }
}
