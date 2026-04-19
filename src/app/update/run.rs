//! `update` command orchestration.

use crate::error::AppError;
use crate::update::version_source::VersionSource;

/// Execute the `update` command with an injected version source.
pub fn execute(source: &dyn VersionSource) -> Result<(), AppError> {
    let current = source.current_version()?;
    println!("Current version: {current}");

    println!("Running upgrade...");
    source.run_upgrade()?;

    println!();
    println!("✓ Upgrade command completed.");
    println!(
        "Run `{} --version` in a new shell to verify the installed version.",
        env!("CARGO_PKG_NAME")
    );

    Ok(())
}
