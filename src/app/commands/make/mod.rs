//! `make` command orchestration — run individual tasks by tag.

use crate::app::DependencyContainer;
use crate::app::commands::deploy_configs;
use crate::domain::error::AppError;
use crate::domain::execution_plan::ExecutionPlan;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::profile::Profile;
use crate::domain::tag;

/// Execute the `make` command: deploy configs and run specified tags.
pub fn execute(
    ctx: &DependencyContainer,
    profile: Profile,
    tag_input: &str,
    overwrite: bool,
    verbose: bool,
) -> Result<(), AppError> {
    let tags_to_run = tag::resolve_tags(tag_input);

    // Validate tags exist in catalog
    for t in &tags_to_run {
        if ctx.ansible.role_for_tag(t).is_none() {
            return Err(AppError::InvalidTag(format!(
                "unknown tag '{t}'. Use 'mev list' to see available tags."
            )));
        }
    }

    let plan = ExecutionPlan::make(profile, tags_to_run, verbose);

    // Deploy configs for roles about to be executed
    deploy_configs::deploy_for_tags(
        &plan.tags,
        &ctx.fs,
        &ctx.local_config_root,
        &ctx.ansible,
        overwrite,
    )?;

    println!("Running tags: {}", plan.tags.join(", "));
    if plan.profile != Profile::Common {
        println!("Profile: {}", plan.profile);
    }
    println!();

    ctx.ansible.run_playbook(plan.profile.as_str(), &plan.tags, plan.verbose)?;

    println!();
    println!("✓ Completed successfully!");

    Ok(())
}
