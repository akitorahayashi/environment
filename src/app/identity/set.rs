use std::io::Write;

use crate::app::AppContext;
use crate::error::AppError;
use crate::identity::model::Identity;
use crate::identity::store::{IdentityState, IdentityStore};

/// Set Git identity configuration interactively.
pub fn execute(ctx: &AppContext) -> Result<(), AppError> {
    println!("Configure mev Git identities");
    println!();

    let existing =
        if ctx.identity_store.exists() { Some(ctx.identity_store.load()?) } else { None };

    let (p_name_default, p_email_default, w_name_default, w_email_default) = match &existing {
        Some(state) => {
            let (pn, pe) = state
                .personal
                .as_ref()
                .map(|id| (id.name().to_string(), id.email().to_string()))
                .unwrap_or_default();
            let (wn, we) = state
                .work
                .as_ref()
                .map(|id| (id.name().to_string(), id.email().to_string()))
                .unwrap_or_default();
            (pn, pe, wn, we)
        }
        None => (String::new(), String::new(), String::new(), String::new()),
    };

    println!("Personal identity:");
    let personal_name = prompt("  Name", &p_name_default)?;
    let personal_email = prompt("  Email", &p_email_default)?;
    println!();

    println!("Work identity:");
    let work_name = prompt("  Name", &w_name_default)?;
    let work_email = prompt("  Email", &w_email_default)?;

    let state = IdentityState {
        personal: Identity::new(personal_name, personal_email),
        work: Identity::new(work_name, work_email),
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
