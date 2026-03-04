//! `make` command orchestration — run individual tasks by tag.

use crate::app::AppContext;
use crate::app::commands::deploy_configs;
use crate::domain::error::AppError;
use crate::domain::execution_plan::ExecutionPlan;
use crate::domain::ports::ansible_executor::AnsibleExecutor;
use crate::domain::ports::tag_catalog::TagCatalog;
use crate::domain::tag;

/// Execute the `make` command: deploy configs and run specified tags.
pub fn execute(
    ctx: &AppContext,
    profile: &str,
    tag_input: &str,
    verbose: bool,
) -> Result<(), AppError> {
    let tags_to_run = tag::resolve_tags(tag_input);

    // Validate tags exist in catalog
    for t in &tags_to_run {
        if ctx.tag_catalog.role_for_tag(t).is_none() {
            return Err(AppError::InvalidTag(format!(
                "unknown tag '{t}'. Use 'mev list' to see available tags."
            )));
        }
    }

    let plan = ExecutionPlan::make(profile, tags_to_run, verbose);

    // Deploy configs for roles about to be executed
    deploy_configs::deploy_for_tags(
        &plan.tags,
        &ctx.ansible_dir,
        &ctx.local_config_root,
        &ctx.tag_catalog,
        &ctx.role_catalog,
    )?;

    println!("Running tags: {}", plan.tags.join(", "));
    if profile != "common" {
        println!("Profile: {profile}");
    }
    println!();

    ctx.ansible_executor.run_playbook(profile, &plan.tags, plan.verbose)?;

    println!();
    println!("✓ Completed successfully!");

    Ok(())
}
