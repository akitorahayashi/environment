//! Deploy the bundled label catalog to a repository.

use clap::Args;

use crate::adapters::{gh, git};
use crate::domain::{label_catalog, repo_target};

#[derive(Args)]
pub struct LabelsDeployArgs {
    /// Target repository in [HOST/]OWNER/REPO format.
    #[arg(short = 'R', long = "repo")]
    pub repo: Option<String>,
}

pub fn run(args: LabelsDeployArgs) -> Result<(), Box<dyn std::error::Error>> {
    let git_adapter = git::GitAdapter::default();
    let origin_url = args.repo.is_none().then(|| git_adapter.current_origin_url()).transpose()?;
    let repo = repo_target::resolve_repo_ref(args.repo.as_deref(), origin_url.as_deref())?;

    let gh_adapter = gh::GhAdapter::default();
    let existing_names = gh_adapter.list_label_names(&repo)?;
    let label_specs = label_catalog::load_bundled_labels()?;

    for spec in label_specs {
        if existing_names.iter().any(|name| name == &spec.name) {
            println!("Replacing label {} in {}...", spec.name, repo.as_gh_repo_arg());
            gh_adapter.delete_label(&repo, &spec.name)?;
        } else {
            println!("Creating label {} in {}...", spec.name, repo.as_gh_repo_arg());
        }

        gh_adapter.create_label(&repo, &spec)?;
    }

    println!("Deployed bundled labels to {}.", repo.as_gh_repo_arg());
    Ok(())
}
