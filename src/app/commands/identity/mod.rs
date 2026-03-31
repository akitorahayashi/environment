//! `identity` command orchestration — show and set Git identities.

use std::io::Write;

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::identity::Identity;
use crate::domain::ports::identity_store::{IdentityState, IdentityStore};

/// Show current Git identity configuration.
pub fn show(ctx: &DependencyContainer) -> Result<(), AppError> {
    if !ctx.identity_store.exists() {
        eprintln!("No identity configuration found.");
        eprintln!("Run 'mev identity set' to configure.");
        return Err(AppError::Config("no identity configuration found".to_string()));
    }

    let state = ctx.identity_store.load()?;
    let path = ctx.identity_store.identity_path();

    println!("Identity file: {}", path.display());
    println!();
    println!("{:<12} {:<20} Email", "Profile", "Name");
    println!("{:-<12} {:-<20} {:-<30}", "", "", "");
    println!("{:<12} {:<20} {}", "personal", state.personal.name, state.personal.email);
    println!("{:<12} {:<20} {}", "work", state.work.name, state.work.email);

    Ok(())
}

/// Set Git identity configuration interactively.
pub fn set(ctx: &DependencyContainer) -> Result<(), AppError> {
    println!("Configure mev Git identities");
    println!();

    let existing =
        if ctx.identity_store.exists() { Some(ctx.identity_store.load()?) } else { None };

    let (p_name_default, p_email_default, w_name_default, w_email_default) = match &existing {
        Some(state) => (
            state.personal.name.as_str(),
            state.personal.email.as_str(),
            state.work.name.as_str(),
            state.work.email.as_str(),
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

    let state = IdentityState {
        personal: Identity { name: personal_name, email: personal_email },
        work: Identity { name: work_name, email: work_email },
    };

    ctx.identity_store.save(&state)?;

    println!();
    println!("Identity configuration saved to {}", ctx.identity_store.identity_path().display());

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
