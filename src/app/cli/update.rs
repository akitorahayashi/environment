//! CLI input contract for the `update` command.

use crate::app::api;
use crate::domain::error::AppError;

pub fn run() -> Result<(), AppError> {
    api::update()
}
