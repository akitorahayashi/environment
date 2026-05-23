//! `make` command orchestration — run individual tasks by tag.

use std::collections::HashSet;

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_order;
use crate::provisioning::execution_plan::ExecutionPlan;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::runner::ProvisioningRunner;
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
    let ordered_units =
        execution_order::order_units(normalized, ctx.provisioning.order_constraints())?;
    let plan = ExecutionPlan::make(profile, ordered_units, verbose);

    // Deploy configs for roles about to be executed
    role_configs::deploy_for_tags(
        &plan.ansible_tags(),
        &ctx.host_fs,
        &ctx.local_config_root,
        &ctx.provisioning,
        &ctx.provisioning,
        overwrite,
    )?;

    println!("Running units: {}", plan.unit_names().join(", "));
    if plan.profile != Profile::Global {
        println!("Profile: {}", plan.profile);
    }
    if plan.verbose {
        for unit in &plan.units {
            println!("{} => {}", unit.name, unit.ansible_tags.join(","));
        }
    }
    println!();

    for unit in &plan.units {
        ctx.provisioning.run_playbook(plan.profile.as_str(), &unit.ansible_tags, plan.verbose)?;
    }

    println!();
    println!("✓ Completed successfully!");

    Ok(())
}
