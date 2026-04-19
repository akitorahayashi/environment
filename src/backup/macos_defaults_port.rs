//! macOS defaults port — interface for reading macOS system preferences.

use crate::error::AppError;

/// Reads macOS system preference values via the `defaults` command.
pub trait MacosDefaultsPort {
    /// Read a key from a domain, returning `None` if the key does not exist.
    fn read_key(&self, domain: &str, key: &str) -> Result<Option<String>, AppError>;
}
