//! `create` command orchestration — full environment setup.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_plan::ExecutionPlan;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::runner::{PlaybookVars, ProvisioningRunner};

const CASK_PHASE_TAG: &str = ExecutionPlan::CASK_PHASE_TAG;
const FORMULA_PHASE_TAG: &str = ExecutionPlan::FORMULA_PHASE_TAG;

/// Execute the `create` command: deploy configs and run full setup tags.
pub fn execute(
    ctx: &AppContext,
    profile: Profile,
    overwrite: bool,
    verbose: bool,
) -> Result<(), AppError> {
    let full_setup_tags = ctx.provisioning.full_setup_tags();

    // Validate all tags exist in catalog
    let all_catalog_tags: std::collections::HashSet<String> =
        ctx.provisioning.all_tags().into_iter().collect();
    let invalid: Vec<&String> =
        full_setup_tags.iter().filter(|t| !all_catalog_tags.contains(*t)).collect();
    if !invalid.is_empty() {
        let names: Vec<String> = invalid.iter().map(|t| (*t).to_string()).collect();
        return Err(AppError::InvalidTag(names.join(", ")));
    }

    let plan = ExecutionPlan::new(
        profile,
        full_setup_tags.to_vec(),
        ctx.provisioning.tap_requirements(),
        ctx.provisioning.formula_requirements(),
        ctx.provisioning.cask_requirements(),
        verbose,
    );

    println!();
    println!("mev: Creating {} environment", plan.profile);
    let runs_full_formulae = plan.runs_full_formulae();
    let setup_tags = plan.execution_tags();
    let formula_phase_count = usize::from(
        runs_full_formulae || !plan.tap_tokens.is_empty() || !plan.formula_tokens.is_empty(),
    );
    let cask_phase_count = usize::from(!plan.cask_tokens.is_empty());
    let phase_count = formula_phase_count + cask_phase_count;
    println!("This will run {} tasks.", setup_tags.len() + phase_count);
    println!();

    // Deploy configs for roles about to be executed
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

    if formula_phase_count > 0 {
        let total = setup_tags.len() + phase_count;
        let label = if runs_full_formulae {
            "Installing formulae".to_string()
        } else {
            format!("Installing required formulae: {}", plan.formula_tokens.join(", "))
        };
        println!("[1/{total}] {label}");
        let vars = if runs_full_formulae {
            PlaybookVars::default()
        } else {
            PlaybookVars::brew_formulae(plan.tap_tokens.clone(), plan.formula_tokens.clone())
        };
        ctx.provisioning
            .run_playbook(
                plan.profile.as_str(),
                &[FORMULA_PHASE_TAG.to_string()],
                &vars,
                plan.verbose,
            )
            .inspect_err(|e| {
                eprintln!("Failed at step 1/{total}: required formulae: {e}");
            })?;
        println!("  ✓ Completed");
    }

    if !plan.cask_tokens.is_empty() {
        let step = formula_phase_count + 1;
        let total = setup_tags.len() + phase_count;
        println!("[{step}/{total}] Installing required casks: {}", plan.cask_tokens.join(", "));
        ctx.provisioning
            .run_playbook(
                plan.profile.as_str(),
                &[CASK_PHASE_TAG.to_string()],
                &PlaybookVars::brew_casks(plan.cask_tokens.clone()),
                plan.verbose,
            )
            .inspect_err(|e| {
                eprintln!("Failed at step {step}/{total}: required casks: {e}");
            })?;
        println!("  ✓ Completed");
    }

    // Execute each tag
    for (i, tag) in setup_tags.iter().enumerate() {
        let step = i + 1 + phase_count;
        let total = setup_tags.len() + phase_count;
        println!("[{step}/{total}] Running: {tag}");

        ctx.provisioning
            .run_playbook(
                plan.profile.as_str(),
                std::slice::from_ref(tag),
                &PlaybookVars::default(),
                plan.verbose,
            )
            .inspect_err(|e| {
                eprintln!("Failed at step {step}/{total}: {tag}: {e}");
            })?;
        println!("  ✓ Completed");
    }

    println!();
    println!("✓ Environment created successfully!");
    println!("Profile: {}", plan.profile);

    println!();
    println!("Optional steps (skipped for stability/speed):");
    println!("  Additional GUI Applications:  mev make br-c --profile {}", plan.profile);

    Ok(())
}
