//! `create` command orchestration — full environment setup.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_plan::ExecutionPlan;
use crate::provisioning::profile::Profile;
use crate::provisioning::role_configs;
use crate::provisioning::runner::{PlaybookVars, ProvisioningRunner};

const CASK_PHASE_TAG: &str = "brew-cask";

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

    let plan = ExecutionPlan::full_setup(
        profile,
        full_setup_tags.to_vec(),
        ctx.provisioning.cask_requirements(),
        verbose,
    );

    println!();
    println!("mev: Creating {} environment", plan.profile);
    let cask_phase_count = usize::from(!plan.cask_tokens.is_empty());
    println!("This will run {} tasks.", plan.tags.len() + cask_phase_count);
    println!();

    // Deploy configs for roles about to be executed
    let mut config_tags = plan.tags.clone();
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

    if !plan.cask_tokens.is_empty() {
        let total = plan.tags.len() + 1;
        println!("[1/{total}] Installing required casks: {}", plan.cask_tokens.join(", "));
        ctx.provisioning
            .run_playbook(
                plan.profile.as_str(),
                &[CASK_PHASE_TAG.to_string()],
                &PlaybookVars::brew_casks(plan.cask_tokens.clone()),
                plan.verbose,
            )
            .inspect_err(|e| {
                eprintln!("Failed at step 1/{total}: required casks: {e}");
            })?;
        println!("  ✓ Completed");
    }

    // Execute each tag
    for (i, tag) in plan.tags.iter().enumerate() {
        let step = i + 1 + cask_phase_count;
        let total = plan.tags.len() + cask_phase_count;
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
    println!("  Ollama Models:     mev make ollama-models");
    println!("  MLX Models:        mev make mlx-models");

    Ok(())
}
