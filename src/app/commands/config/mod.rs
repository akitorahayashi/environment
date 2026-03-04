//! `config` command orchestration — show, set, and deploy configuration.

use std::io::Write;
use std::path::Path;

use crate::app::AppContext;
use crate::domain::config::VcsIdentity;
use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::ports::config_store::{ConfigStore, MevConfig};

/// Show current VCS identity configuration.
pub fn show(ctx: &AppContext) -> Result<(), AppError> {
    if !ctx.config_store.exists() {
        eprintln!("No configuration found.");
        eprintln!("Run 'mev config set' to configure.");
        return Err(AppError::Config("no configuration found".to_string()));
    }

    let config = ctx.config_store.load()?;
    let path = ctx.config_store.config_path();

    println!("Config file: {}", path.display());
    println!();
    println!("{:<12} {:<20} Email", "Profile", "Name");
    println!("{:-<12} {:-<20} {:-<30}", "", "", "");
    println!("{:<12} {:<20} {}", "personal", config.personal.name, config.personal.email);
    println!("{:<12} {:<20} {}", "work", config.work.name, config.work.email);

    Ok(())
}

/// Set VCS identity configuration interactively.
pub fn set(ctx: &AppContext) -> Result<(), AppError> {
    println!("Configure mev VCS identities");
    println!();

    let existing = if ctx.config_store.exists() { Some(ctx.config_store.load()?) } else { None };

    let (p_name_default, p_email_default, w_name_default, w_email_default) = match &existing {
        Some(cfg) => (
            cfg.personal.name.as_str(),
            cfg.personal.email.as_str(),
            cfg.work.name.as_str(),
            cfg.work.email.as_str(),
        ),
        None => ("", "", "", ""),
    };

    println!("Personal identity:");
    let personal_name = prompt("  Name", p_name_default)?;
    let personal_email = prompt("  Email", p_email_default)?;
    println!();

    println!("Work identity:");
    let work_name = prompt("  Name", w_name_default)?;
    let work_email = prompt("  Email", w_email_default)?;

    let config = MevConfig {
        personal: VcsIdentity { name: personal_name, email: personal_email },
        work: VcsIdentity { name: work_name, email: work_email },
    };

    ctx.config_store.save(&config)?;

    println!();
    println!("Configuration saved to {}", ctx.config_store.config_path().display());

    Ok(())
}

/// Deploy role configs from ansible assets to local config root.
pub fn create(ctx: &AppContext, role: Option<String>, overwrite: bool) -> Result<(), AppError> {
    let available = ctx.ansible.roles_with_config()?;

    let roles_to_deploy = if let Some(role_name) = role {
        if !available.contains(&role_name) {
            return Err(AppError::Config(format!(
                "role '{role_name}' has no config directory. Available: {}",
                available.join(", ")
            )));
        }
        vec![role_name]
    } else {
        if available.is_empty() {
            println!("No roles with config directories found.");
            return Ok(());
        }
        available
    };

    for role_name in &roles_to_deploy {
        let source = ctx.ansible_dir.join("roles").join(role_name).join("config");
        let target = ctx.local_config_root.join(role_name);

        if target.exists() && !overwrite {
            println!("  {role_name}: config exists (use --overwrite to replace)");
            continue;
        }
        let staging = ctx.local_config_root.join(format!(".{role_name}.staging"));
        if staging.exists() {
            std::fs::remove_dir_all(&staging).map_err(|e| {
                AppError::Config(format!("failed to clean staging for {role_name}: {e}"))
            })?;
        }
        copy_dir_recursive(&source, &staging)?;
        if target.exists() {
            std::fs::remove_dir_all(&target).map_err(|e| {
                AppError::Config(format!("failed to remove existing config for {role_name}: {e}"))
            })?;
        }
        std::fs::rename(&staging, &target).map_err(|e| {
            AppError::Config(format!("failed to activate config for {role_name}: {e}"))
        })?;
        println!("✓ {role_name}: config deployed");
    }

    Ok(())
}

fn prompt(label: &str, default: &str) -> Result<String, AppError> {
    if default.is_empty() {
        print!("{label}: ");
    } else {
        print!("{label} [{default}]: ");
    }
    std::io::stdout().flush()?;
    let mut input = String::new();
    std::io::stdin().read_line(&mut input)?;
    let trimmed = input.trim();
    if trimmed.is_empty() { Ok(default.to_string()) } else { Ok(trimmed.to_string()) }
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<(), AppError> {
    std::fs::create_dir_all(dst)?;
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        if src_path.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}
