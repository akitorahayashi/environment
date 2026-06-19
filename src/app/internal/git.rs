use crate::error::AppError;

pub fn run(command: mev_internal::app::cli::git::GitCommand) -> Result<(), AppError> {
    mev_internal::app::cli::git::run(command).map_err(|e| AppError::Config(e.to_string()))
}
