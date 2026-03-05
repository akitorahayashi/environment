//! CLI input contract for the `list` command.

use crate::adapters::ansible::locator;
use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;

pub fn run() -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = DependencyContainer::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::list::execute(&ctx)
}
