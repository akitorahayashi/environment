//! `make` command orchestration — run individual tasks by tag.

use std::collections::HashSet;

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_order;
use crate::provisioning::execution_plan::LayeredExecutionPlan;
use crate::provisioning::playbook_execution;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::tag_selection;

/// Execute the `make` command: deploy configs and run specified tags.
pub fn execute(
    ctx: &AppContext,
    profile: Profile,
    tags: Vec<String>,
    overwrite: bool,
    verbose: bool,
) -> Result<(), AppError> {
    let atomic_tags: HashSet<String> = ctx.provisioning.all_tags().into_iter().collect();
    let normalized = tag_selection::normalize_requested_tags(
        &tags,
        ctx.provisioning.tag_groups(),
        &atomic_tags,
    )?;
    let layers = execution_order::layer_units(normalized, ctx.provisioning.order_constraints())?;
    let plan = LayeredExecutionPlan::new(profile, layers, verbose);

    // Deploy configs for roles about to be executed
    role_configs::deploy_for_tags(
        &plan.ansible_tags(),
        &ctx.host_fs,
        &ctx.local_config_root,
        &ctx.provisioning,
        &ctx.provisioning,
        overwrite,
    )?;

    println!();
    println!("mev: Running selected provisioning plan");
    println!(
        "This will run {} tasks across {} layers.",
        plan.running_units().len(),
        plan.layer_count()
    );
    println!();

    playbook_execution::run_layered_playbook(
        &ctx.provisioning,
        plan.profile.as_str(),
        &plan.layers,
        plan.verbose,
    )?;

    println!();
    println!("✓ Completed successfully!");

    Ok(())
}
