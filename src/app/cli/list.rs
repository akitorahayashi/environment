//! CLI input contract for the `list` command.

use crate::adapters::package_assets::ansible_asset_locator;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;

pub fn run() -> Result<(), AppError> {
    let ansible_dir = ansible_asset_locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::list::execute(&ctx)
}
