//! Domain-level typed errors.

use std::fmt;

/// Top-level application error.
#[derive(Debug)]
pub enum AppError {
    /// Ansible execution failed.
    AnsibleExecution { message: String, exit_code: Option<i32> },

    /// Invalid profile identifier.
    InvalidProfile(String),

    /// Invalid identity scope identifier.
    InvalidIdentityScope(String),

    /// Invalid or unknown tag.
    InvalidTag(String),

    /// Configuration error.
    Config(String),

    /// Invalid backup component identifier.
    InvalidBackupComponent(String),

    /// Update operation failure.
    Update(String),

    /// Backup operation failed.
    Backup(String),

    /// I/O error.
    Io(std::io::Error),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::AnsibleExecution { message, exit_code } => {
                write!(f, "ansible execution failed: {message}")?;
                if let Some(code) = exit_code {
                    write!(f, " (exit code {code})")?;
                }
                Ok(())
            }
            Self::InvalidProfile(p) => write!(f, "invalid profile: {p}"),
            Self::InvalidIdentityScope(i) => write!(f, "invalid identity scope: {i}"),
            Self::InvalidTag(t) => write!(f, "invalid tag: {t}"),
            Self::InvalidBackupComponent(t) => write!(f, "invalid backup component: {t}"),
            Self::Config(msg) => write!(f, "configuration error: {msg}"),
            Self::Update(msg) => write!(f, "update failed: {msg}"),
            Self::Backup(msg) => write!(f, "backup failed: {msg}"),
            Self::Io(err) => write!(f, "I/O error: {err}"),
        }
    }
}

impl std::error::Error for AppError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io(err) => Some(err),
            _ => None,
        }
    }
}

impl From<std::io::Error> for AppError {
    fn from(err: std::io::Error) -> Self {
        Self::Io(err)
    }
}
