//! CLI input contract for the `update` command.

use crate::error::AppError;

pub fn run() -> Result<(), AppError> {
    crate::update()
}
