//! `make` command orchestration — run individual tasks by tag.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_plan::ExecutionPlan;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::runner::{PlaybookVars, ProvisioningRunner};
use crate::provisioning::tag_selection;

const CASK_PHASE_TAG: &str = ExecutionPlan::CASK_PHASE_TAG;
const FORMULA_PHASE_TAG: &str = ExecutionPlan::FORMULA_PHASE_TAG;

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

    let plan = ExecutionPlan::new(
        profile,
        tags_to_run,
        ctx.provisioning.tap_requirements(),
        ctx.provisioning.formula_requirements(),
        ctx.provisioning.cask_requirements(),
        verbose,
    );

    // Deploy configs for roles about to be executed
    let runs_full_formulae = plan.runs_full_formulae();
    let configure_tags = plan.execution_tags();
    let config_tags = plan.config_deployment_tags();
    role_configs::deploy_for_tags(
        &config_tags,
        &ctx.host_fs,
        &ctx.local_config_root,
        &ctx.provisioning,
        &ctx.provisioning,
        overwrite,
    )?;

    // Materialize coder intermediate entities before the coder role symlinks them.
    if config_tags.iter().any(|tag| ctx.provisioning.role_for_tag(tag) == Some("coder")) {
        crate::app::coder::materialize::execute(ctx)?;
    }

    println!("Running tags: {}", plan.tags.join(", "));
    if !plan.tap_tokens.is_empty() {
        println!("Required taps: {}", plan.tap_tokens.join(", "));
    }
    if !plan.formula_tokens.is_empty() {
        println!("Required formulae: {}", plan.formula_tokens.join(", "));
    }
    if !plan.cask_tokens.is_empty() {
        println!("Required casks: {}", plan.cask_tokens.join(", "));
    }
    if plan.profile != Profile::Global {
        println!("Profile: {}", plan.profile);
    }
    println!();

    if runs_full_formulae {
        ctx.provisioning.run_playbook(
            plan.profile.as_str(),
            &[FORMULA_PHASE_TAG.to_string()],
            &PlaybookVars::default(),
            plan.verbose,
        )?;
    } else if !plan.tap_tokens.is_empty() || !plan.formula_tokens.is_empty() {
        ctx.provisioning.run_playbook(
            plan.profile.as_str(),
            &[FORMULA_PHASE_TAG.to_string()],
            &PlaybookVars::brew_formulae(plan.tap_tokens.clone(), plan.formula_tokens.clone()),
            plan.verbose,
        )?;
    }

    if !plan.cask_tokens.is_empty() {
        ctx.provisioning.run_playbook(
            plan.profile.as_str(),
            &[CASK_PHASE_TAG.to_string()],
            &PlaybookVars::brew_casks(plan.cask_tokens.clone()),
            plan.verbose,
        )?;
    }

    if !configure_tags.is_empty() {
        ctx.provisioning.run_playbook(
            plan.profile.as_str(),
            &configure_tags,
            &PlaybookVars::default(),
            plan.verbose,
        )?;
    }

    println!();
    println!("✓ Completed successfully!");

    Ok(())
}
