//! `switch` command orchestration — VCS identity switching.

use std::process::Command;

use crate::app::AppContext;
use crate::domain::config;
use crate::domain::error::AppError;
use crate::domain::ports::config_store::ConfigStore;

/// Execute the `switch` command: change global git/jj identity.
pub fn execute(ctx: &AppContext, profile_input: &str) -> Result<(), AppError> {
    if !ctx.config_store.exists() {
        eprintln!("No configuration found.");
        eprintln!("Run 'mev config set' first to configure identities.");
        return Err(AppError::Config("no configuration found".to_string()));
    }

    let resolved = config::resolve_switch_profile(profile_input).ok_or_else(|| {
        AppError::InvalidProfile(format!(
            "invalid profile '{profile_input}'. Valid: personal (p), work (w)"
        ))
    })?;

    let identity = ctx
        .config_store
        .get_identity(resolved)?
        .ok_or_else(|| AppError::Config(format!("failed to load {resolved} identity")))?;

    if identity.name.is_empty() || identity.email.is_empty() {
        return Err(AppError::Config(format!(
            "{resolved} identity is not configured. Run 'mev config set' to configure."
        )));
    }

    println!("Switching to {resolved} identity...");

    // Git configuration
    run_git_config("user.name", &identity.name)?;
    run_git_config("user.email", &identity.email)?;

    // Jujutsu configuration (optional — skip if jj not installed)
    if which::which("jj").is_ok() {
        if let Err(e) = run_jj_config("user.name", &identity.name) {
            eprintln!("Warning: jj config user.name failed: {e}");
        }
        if let Err(e) = run_jj_config("user.email", &identity.email) {
            eprintln!("Warning: jj config user.email failed: {e}");
        }
    }

    // Show current configuration
    let (name, email) = get_current_git_user();
    println!();
    println!("Switched to {resolved} identity");
    println!("  Name:  {name}");
    println!("  Email: {email}");

    Ok(())
}

fn run_git_config(key: &str, value: &str) -> Result<(), AppError> {
    let output = Command::new("git")
        .args(["config", "--global", key, value])
        .output()
        .map_err(|e| AppError::Config(format!("failed to run git config: {e}")))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(AppError::Config(format!("git config --global {key} failed: {stderr}")));
    }
    Ok(())
}

fn run_jj_config(key: &str, value: &str) -> Result<(), AppError> {
    let output = Command::new("jj")
        .args(["config", "set", "--user", key, value])
        .output()
        .map_err(|e| AppError::Config(format!("failed to run jj config: {e}")))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(AppError::Config(format!("jj config set {key} failed: {stderr}")));
    }
    Ok(())
}

fn get_current_git_user() -> (String, String) {
    let name = Command::new("git")
        .args(["config", "--global", "user.name"])
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default();
    let email = Command::new("git")
        .args(["config", "--global", "user.email"])
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default();
    (name, email)
}
