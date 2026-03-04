//! SSH key and host configuration.

use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::Command;

use clap::Subcommand;

const VALID_KEY_TYPES: &[&str] = &["ed25519", "rsa", "ecdsa"];

#[derive(Subcommand)]
pub enum SshCommand {
    /// Generate a key and config snippet for a host.
    Gk {
        /// SSH key type.
        #[arg(value_name = "TYPE")]
        key_type: String,
        /// Host alias.
        host: String,
    },

    /// List configured SSH hosts.
    Ls,

    /// Remove SSH key and config for a host.
    Rm {
        /// Host alias.
        host: String,
    },
}

pub fn run(cmd: SshCommand) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        SshCommand::Gk { key_type, host } => generate_key(&key_type, &host),
        SshCommand::Ls => list_hosts(),
        SshCommand::Rm { host } => remove_host(&host),
    }
}

fn home_dir() -> PathBuf {
    if let Ok(home) = std::env::var("HOME") {
        return PathBuf::from(home);
    }
    if let Some(home) = dirs::home_dir() {
        return home;
    }
    eprintln!("Error: Could not determine home directory.");
    std::process::exit(1);
}

fn ssh_dir() -> PathBuf {
    home_dir().join(".ssh")
}

fn conf_dir() -> PathBuf {
    ssh_dir().join("conf.d")
}

fn is_valid_host(host: &str) -> bool {
    !host.is_empty() && host.chars().all(|c| c.is_ascii_alphanumeric() || "._-".contains(c))
}

fn generate_key(key_type: &str, host: &str) -> Result<(), Box<dyn std::error::Error>> {
    if !VALID_KEY_TYPES.contains(&key_type) {
        eprintln!(
            "Error: Unsupported key type '{}' (allowed: {}).",
            key_type,
            VALID_KEY_TYPES.join("|")
        );
        std::process::exit(1);
    }

    if !is_valid_host(host) {
        eprintln!("Error: Invalid host '{host}' (allowed: [A-Za-z0-9._-]+).");
        std::process::exit(1);
    }

    let ssh = ssh_dir();
    let conf = conf_dir();
    fs::create_dir_all(&ssh)?;
    fs::create_dir_all(&conf)?;

    let key_path = ssh.join(format!("id_{key_type}_{host}"));
    let config_path = conf.join(format!("{host}.conf"));
    let pub_path = key_path.with_extension("pub");

    if config_path.exists() {
        eprintln!("Error: Config for host '{host}' already exists.");
        std::process::exit(1);
    }

    if key_path.exists() || pub_path.exists() {
        eprintln!("Error: Key files already exist: '{}'(.pub).", key_path.display());
        std::process::exit(1);
    }

    let keygen_result = Command::new("ssh-keygen")
        .args(["-q", "-t", key_type, "-f"])
        .arg(&key_path)
        .args(["-C", host, "-N", ""])
        .status();

    let cleanup = |kp: &PathBuf, pp: &PathBuf| {
        let _ = fs::remove_file(kp);
        let _ = fs::remove_file(pp);
    };

    match keygen_result {
        Ok(status) if status.success() => {}
        Ok(status) => {
            cleanup(&key_path, &pub_path);
            eprintln!("Error: ssh-keygen exited with code {}", status.code().unwrap_or(1));
            std::process::exit(1);
        }
        Err(e) => {
            cleanup(&key_path, &pub_path);
            eprintln!("Error: {e}");
            std::process::exit(1);
        }
    }

    let config_content = format!(
        "Host {host}\n\
         \x20\x20HostName {host}\n\
         \x20\x20User git\n\
         \x20\x20IdentityFile ~/.ssh/id_{key_type}_{host}\n\
         \x20\x20IdentitiesOnly yes\n"
    );

    if let Err(e) = fs::write(&config_path, &config_content) {
        cleanup(&key_path, &pub_path);
        eprintln!("Error: {e}");
        std::process::exit(1);
    }
    fs::set_permissions(&config_path, fs::Permissions::from_mode(0o600))?;

    println!("✅ SSH key and config for '{host}' created.");
    if pub_path.exists() {
        let pub_key = fs::read_to_string(&pub_path)?;
        println!("🔑 Public key:");
        println!("{}", pub_key.trim());
    }
    Ok(())
}

fn list_hosts() -> Result<(), Box<dyn std::error::Error>> {
    let hosts = collect_hosts(&conf_dir())?;

    for host in hosts {
        println!("{host}");
    }
    Ok(())
}

fn collect_hosts(conf: &Path) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    if !conf.exists() {
        return Ok(Vec::new());
    }

    let mut hosts: Vec<String> = fs::read_dir(conf)?
        .filter_map(|e| e.ok())
        .filter(|e| e.path().extension().and_then(|x| x.to_str()) == Some("conf"))
        .filter_map(|e| e.path().file_stem().map(|s| s.to_string_lossy().into_owned()))
        .collect();
    hosts.sort();
    Ok(hosts)
}

fn remove_host(host: &str) -> Result<(), Box<dyn std::error::Error>> {
    if !is_valid_host(host) {
        eprintln!("Error: Invalid host '{host}' (allowed: [A-Za-z0-9._-]+).");
        std::process::exit(1);
    }

    let conf = conf_dir();
    let base = conf.canonicalize().unwrap_or_else(|_| conf.clone());
    let config_path = conf.join(format!("{host}.conf"));
    let canon = config_path.canonicalize().unwrap_or_else(|_| config_path.clone());

    if !canon.starts_with(&base) {
        eprintln!("Error: Refusing to operate outside {}.", base.display());
        std::process::exit(1);
    }

    if !config_path.exists() {
        eprintln!("Error: Config for host '{host}' not found.");
        std::process::exit(1);
    }

    // Extract IdentityFile from config
    let content = fs::read_to_string(&config_path)?;
    let mut identity_file: Option<PathBuf> = None;
    for line in content.lines() {
        let trimmed = line.trim();
        if trimmed.to_lowercase().starts_with("identityfile") {
            if let Some(path_str) = trimmed.split_whitespace().nth(1) {
                let expanded = if let Some(stripped) = path_str.strip_prefix("~/") {
                    home_dir().join(stripped)
                } else {
                    PathBuf::from(path_str)
                };
                identity_file = Some(expanded);
            }
            break;
        }
    }

    if let Some(ref id_file) = identity_file {
        let ssh_base = ssh_dir().canonicalize().unwrap_or_else(|_| ssh_dir());
        let candidate = id_file.canonicalize().unwrap_or_else(|_| id_file.clone());
        if !candidate.starts_with(&ssh_base) {
            eprintln!("Error: Refusing to remove key outside {}.", ssh_base.display());
            std::process::exit(1);
        }
        let pub_file = id_file.with_extension("pub");
        for path in [id_file.as_path(), pub_file.as_path()] {
            if path.exists() {
                let _ = fs::remove_file(path);
            }
        }
        println!("🗑️ Removed key files for {host}.");
    }

    fs::remove_file(&config_path)?;
    println!("🗑️ Removed config file for '{host}'.");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn valid_hosts_are_accepted() {
        assert!(is_valid_host("example.com"));
        assert!(is_valid_host("my-host"));
        assert!(is_valid_host("host_1"));
    }

    #[test]
    fn invalid_host_with_space_is_rejected() {
        assert!(!is_valid_host("bad host!"));
    }

    #[test]
    fn invalid_host_empty_is_rejected() {
        assert!(!is_valid_host(""));
    }

    #[test]
    fn valid_key_types_are_known() {
        assert!(VALID_KEY_TYPES.contains(&"ed25519"));
        assert!(VALID_KEY_TYPES.contains(&"rsa"));
        assert!(VALID_KEY_TYPES.contains(&"ecdsa"));
    }

    #[test]
    fn invalid_key_type_is_not_known() {
        assert!(!VALID_KEY_TYPES.contains(&"invalid-type"));
    }

    #[test]
    fn list_hosts_succeeds_when_conf_dir_absent() {
        let dir = tempfile::tempdir().unwrap();
        let absent_conf = dir.path().join("conf.d");
        let hosts = collect_hosts(&absent_conf).unwrap();
        assert!(hosts.is_empty());
    }
}
