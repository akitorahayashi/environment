//! `make` command orchestration — run individual tasks by tag.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_plan::ExecutionPlan;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::runner::ProvisioningRunner;
use crate::provisioning::tag_selection;

/// Execute the `make` command: deploy configs and run specified tags.
pub fn execute(
    ctx: &AppContext,
    profile: Profile,
    tag_input: &str,
    overwrite: bool,
    verbose: bool,
) -> Result<(), AppError> {
    let tags_to_run = tag_selection::resolve_tags(tag_input, ctx.provisioning.tag_groups());

    // Validate tags exist in catalog
    for t in &tags_to_run {
        if ctx.provisioning.role_for_tag(t).is_none() {
            return Err(AppError::InvalidTag(format!(
                "'{t}'. Use 'mev list' to see available tags."
            )));
        }
    }

    let plan = ExecutionPlan::make(profile, tags_to_run, verbose);

    // Deploy configs for roles about to be executed
    role_configs::deploy_for_tags(
        &plan.tags,
        &ctx.host_fs,
        &ctx.local_config_root,
        &ctx.provisioning,
        &ctx.provisioning,
        overwrite,
    )?;

    println!("Running tags: {}", plan.tags.join(", "));
    if plan.profile != Profile::Global {
        println!("Profile: {}", plan.profile);
    }
    println!();

    ctx.provisioning.run_playbook(plan.profile.as_str(), &plan.tags, plan.verbose)?;

    println!();
    println!("✓ Completed successfully!");

    Ok(())
}
