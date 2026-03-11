//! Git CLI adapter.

use std::fs;
use std::path::Path;
use std::process::Command;

use crate::adapters::process;

pub fn delete_submodule_worktree(submodule_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    process::run_status(
        git_command(["submodule", "deinit", "-f", submodule_path]),
        &format!("git submodule deinit -f {submodule_path}"),
    )?;

    process::run_status(
        git_command(["rm", "-f", "-r", submodule_path]),
        &format!("git rm -f -r {submodule_path}"),
    )?;

    Ok(())
}

pub fn remove_submodule_module_dir(submodule_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    let modules_path = Path::new(".git").join("modules").join(submodule_path);
    if modules_path.exists() {
        fs::remove_dir_all(&modules_path)?;
    }
    Ok(())
}

pub fn remove_submodule_config_section(
    submodule_path: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let output = process::run_output(
        git_command(["config", "--remove-section", &format!("submodule.{submodule_path}")]),
        &format!("git config --remove-section submodule.{submodule_path}"),
    );

    match output {
        Ok(_) => Ok(()),
        Err(err) if err.to_string().contains("No such section") => Ok(()),
        Err(err) => Err(err),
    }
}

pub fn current_origin_url() -> Result<String, Box<dyn std::error::Error>> {
    let output = process::run_output(
        git_command(["remote", "get-url", "origin"]),
        "git remote get-url origin",
    )?;
    Ok(String::from_utf8(output.stdout)?.trim().to_owned())
}

fn git_command<const N: usize, S>(args: [S; N]) -> Command
where
    S: AsRef<std::ffi::OsStr>,
{
    let mut command = Command::new("git");
    command.args(args);
    command
}
