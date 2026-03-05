//! CLI input contract for the `update` command.

use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;

pub fn run() -> Result<(), AppError> {
    let ctx = DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))?;
    commands::update::execute(&ctx.version_source)
}
