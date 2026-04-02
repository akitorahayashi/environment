//! macOS defaults adapter.

use std::process::Command;

use crate::domain::error::AppError;
use crate::domain::ports::macos_defaults::MacosDefaultsPort;

/// Keys that must be read with `defaults read -g <key>` instead of
/// `defaults read <domain> <key>` because macOS registers them
/// under the global domain regardless of the preference pane domain.
const SPECIAL_GLOBAL_KEYS: &[&str] = &[
    "com.apple.keyboard.fnState",
    "com.apple.trackpad.scaling",
    "com.apple.sound.beep.feedback",
    "com.apple.sound.beep.sound",
];

pub struct MacosDefaultsCli;

impl MacosDefaultsPort for MacosDefaultsCli {
    fn read_key(&self, domain: &str, key: &str) -> Result<Option<String>, AppError> {
        let output = if SPECIAL_GLOBAL_KEYS.contains(&key) {
            Command::new("defaults").args(["read", "-g", key]).output()
        } else {
            Command::new("defaults").args(["read", domain, key]).output()
        };

        match output {
            Ok(o) if o.status.success() => {
                Ok(Some(String::from_utf8_lossy(&o.stdout).trim().to_string()))
            }
            Ok(o) => {
                let stderr = String::from_utf8_lossy(&o.stderr);
                if stderr.contains("does not exist") {
                    Ok(None)
                } else {
                    Err(AppError::Backup(format!(
                        "defaults read failed for domain='{domain}', key='{key}': {}",
                        stderr.trim()
                    )))
                }
            }
            Err(e) => Err(AppError::Backup(format!(
                "failed to execute defaults for domain='{domain}', key='{key}': {e}"
            ))),
        }
    }
}
