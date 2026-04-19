use crate::app::AppContext;
use crate::error::AppError;
use crate::identity::store::IdentityStore;

/// Show current Git identity configuration.
pub fn execute(ctx: &AppContext) -> Result<(), AppError> {
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
    if let Some(personal) = state.personal {
        println!("{:<12} {:<20} {}", "personal", personal.name(), personal.email());
    } else {
        println!("{:<12} {:<20}", "personal", "Not configured");
    }
    if let Some(work) = state.work {
        println!("{:<12} {:<20} {}", "work", work.name(), work.email());
    } else {
        println!("{:<12} {:<20}", "work", "Not configured");
    }

    Ok(())
}
