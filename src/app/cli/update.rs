//! CLI input contract for the `update` command.

use crate::app::commands;
use crate::domain::error::AppError;

pub fn run() -> Result<(), AppError> {
    let source = crate::adapters::version_source::cargo::CargoVersion;
    commands::update::execute(&source)
}
