//! `update` command orchestration — version check and upgrade.

use crate::domain::error::AppError;
use crate::domain::ports::version_source::VersionSource;

/// Execute the `update` command with an injected version source.
pub fn execute(source: &dyn VersionSource) -> Result<(), AppError> {
    let current = source.current_version()?;
    println!("Current version: {current}");

    println!("Checking for updates...");
    let latest = match source.latest_version() {
        Ok(v) => v,
        Err(_) => {
            println!();
            println!("✓ Version check unavailable. You are on version {current}.");
            return Ok(());
        }
    };

    println!("Latest version:  {latest}");

    if !source.needs_update(&current, &latest) {
        println!();
        println!("✓ You are already on the latest version!");
        return Ok(());
    }

    println!();
    println!("Update available: {current} → {latest}");

    source.run_upgrade()?;

    let new_version = source.current_version()?;
    println!();
    println!("✓ Successfully updated to version {new_version}!");

    Ok(())
}
