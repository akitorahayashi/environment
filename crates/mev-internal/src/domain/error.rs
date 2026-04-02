use thiserror::Error;

#[derive(Debug, Error)]
pub enum DomainError {
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    #[error("UTF-8 parsing error: {0}")]
    Utf8(#[from] std::string::FromUtf8Error),

    #[error("JSON serialization error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("{0}")]
    InvalidRepositoryRef(String),

    #[error("unsupported remote url '{0}'")]
    UnsupportedRemoteUrl(String),

    #[error("invalid submodule path: {0}")]
    InvalidSubmodulePath(String),

    #[error("{0}")]
    MissingRepository(String),

    #[error("{0}")]
    ProcessFailed(String),

    #[error("failed to execute '{0}': {1}")]
    CommandExecution(String, #[source] std::io::Error),
}
