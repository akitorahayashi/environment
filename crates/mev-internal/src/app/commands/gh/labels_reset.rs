//! Delete all labels from a repository.

use clap::Args;

use crate::adapters::{gh, git};
use crate::domain::repo_target;

#[derive(Args)]
pub struct LabelsResetArgs {
    /// Target repository in [HOST/]OWNER/REPO format.
    #[arg(short = 'R', long = "repo")]
    pub repo: Option<String>,
}

pub fn run(args: LabelsResetArgs) -> Result<(), Box<dyn std::error::Error>> {
    let git_adapter = git::GitAdapter::default();
    let origin_url = args.repo.is_none().then(|| git_adapter.current_origin_url()).transpose()?;
    let repo = repo_target::resolve_repo_ref(args.repo.as_deref(), origin_url.as_deref())?;

    let gh_adapter = gh::GhAdapter::default();
    let names = gh_adapter.list_label_names(&repo)?;

    if names.is_empty() {
        println!("No labels to delete in {}.", repo.as_gh_repo_arg());
        return Ok(());
    }

    for name in names {
        println!("Deleting label {name} from {}...", repo.as_gh_repo_arg());
        gh_adapter.delete_label(&repo, &name)?;
    }

    println!("Deleted all labels from {}.", repo.as_gh_repo_arg());
    Ok(())
}
