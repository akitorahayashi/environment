//! `create` command orchestration — full environment setup.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_order;
use crate::provisioning::execution_plan::{ExecutionUnit, LayeredExecutionPlan};
use crate::provisioning::playbook_execution;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;

/// Execute the `create` command: deploy configs and run full setup tags.
pub fn execute(
    ctx: &AppContext,
    profile: Profile,
    overwrite: bool,
    verbose: bool,
) -> Result<(), AppError> {
    let full_setup_tags = ctx.provisioning.full_setup_tags();

    let all_catalog_tags: std::collections::HashSet<String> =
        ctx.provisioning.all_tags().into_iter().collect();
    let invalid: Vec<&String> =
        full_setup_tags.iter().filter(|tag| !all_catalog_tags.contains(*tag)).collect();
    if !invalid.is_empty() {
        let names: Vec<String> = invalid.iter().map(|tag| (*tag).to_string()).collect();
        return Err(AppError::InvalidTag(names.join(", ")));
    }

    let units: Vec<ExecutionUnit> =
        full_setup_tags.iter().cloned().map(ExecutionUnit::atomic).collect();
    let layers = execution_order::layer_units(units, ctx.provisioning.order_constraints())?;
    let plan = LayeredExecutionPlan::full_setup(profile, layers, verbose);

    println!();
    println!("mev: Creating {} environment", plan.profile);
    println!(
        "This will run {} tasks across {} layers.",
        plan.running_units().len(),
        plan.layer_count()
    );
    println!();

    // Deploy configs for roles about to be executed
    role_configs::deploy_for_tags(
        &plan.ansible_tags(),
        &ctx.host_fs,
        &ctx.local_config_root,
        &ctx.provisioning,
        &ctx.provisioning,
        overwrite,
    )?;

    playbook_execution::run_layered_playbook(
        &ctx.provisioning,
        plan.profile.as_str(),
        &plan.layers,
        plan.verbose,
    )?;

    println!();
    println!("✓ Environment created successfully!");
    println!("Profile: {}", plan.profile);

    println!();
    println!("Optional steps (skipped for stability/speed):");
    println!("  GUI Applications:  mev make br-c --profile {}", plan.profile);
    println!("  Ollama Models:     mev make ollama-models");
    println!("  MLX Models:        mev make mlx-models");

    Ok(())
}
