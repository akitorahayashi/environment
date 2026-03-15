//! CLI input contract for the `list` command.

use crate::app::api;
use crate::domain::error::AppError;

pub fn run() -> Result<(), AppError> {
    api::list()
}
