//! `make` command orchestration — run individual tasks by tag.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_plan::ExecutionPlan;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::runner::{PlaybookVars, ProvisioningRunner};
use crate::provisioning::tag_selection;

const CASK_PHASE_TAG: &str = "brew-cask";
const FORMULA_PHASE_TAG: &str = "brew-formulae";

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

    let plan = ExecutionPlan::make(
        profile,
        tags_to_run,
        ctx.provisioning.tap_requirements(),
        ctx.provisioning.formula_requirements(),
        ctx.provisioning.cask_requirements(),
        verbose,
    );

    // Deploy configs for roles about to be executed
    let mut config_tags = plan.tags.clone();
    let runs_full_formulae = plan.tags.iter().any(|tag| tag == FORMULA_PHASE_TAG);
    let configure_tags: Vec<String> = if runs_full_formulae {
        plan.tags.iter().filter(|tag| tag.as_str() != FORMULA_PHASE_TAG).cloned().collect()
    } else {
        plan.tags.clone()
    };
    if (!plan.tap_tokens.is_empty() || !plan.formula_tokens.is_empty())
        && !runs_full_formulae
        && !config_tags.iter().any(|tag| tag == FORMULA_PHASE_TAG)
    {
        config_tags.push(FORMULA_PHASE_TAG.to_string());
    }
    if !plan.cask_tokens.is_empty() && !config_tags.iter().any(|tag| tag == CASK_PHASE_TAG) {
        config_tags.push(CASK_PHASE_TAG.to_string());
    }
    role_configs::deploy_for_tags(
        &config_tags,
        &ctx.host_fs,
        &ctx.local_config_root,
        &ctx.provisioning,
        &ctx.provisioning,
        overwrite,
    )?;

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
