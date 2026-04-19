//! CLI input contract for the `list` command.

use crate::error::AppError;

pub fn run() -> Result<(), AppError> {
    crate::list()
}
