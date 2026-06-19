use crate::error::AppError;

pub fn run(command: mev_internal::app::cli::gh::GhCommand) -> Result<(), AppError> {
    mev_internal::app::cli::gh::run(command).map_err(|e| AppError::Config(e.to_string()))
}
