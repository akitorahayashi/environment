//! `create` command orchestration — full environment setup.

use crate::app::DependencyContainer;
use crate::app::commands::deploy_configs;
use crate::domain::error::AppError;
use crate::domain::execution_plan::ExecutionPlan;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::profile::Profile;

/// Execute the `create` command: deploy configs and run full setup tags.
pub fn execute(
    ctx: &DependencyContainer,
    profile: Profile,
    overwrite: bool,
    verbose: bool,
) -> Result<(), AppError> {
    let full_setup_tags = ctx.ansible.full_setup_tags();

    // Validate all tags exist in catalog
    let all_catalog_tags: std::collections::HashSet<String> =
        ctx.ansible.all_tags().into_iter().collect();
    let invalid: Vec<&String> =
        full_setup_tags.iter().filter(|t| !all_catalog_tags.contains(*t)).collect();
    if !invalid.is_empty() {
        let names: Vec<String> = invalid.iter().map(|t| (*t).to_string()).collect();
        return Err(AppError::InvalidTag(names.join(", ")));
    }

    let plan = ExecutionPlan::full_setup(profile, full_setup_tags.to_vec(), verbose);

    println!();
    println!("mev: Creating {} environment", plan.profile);
    println!("This will run {} tasks.", plan.tags.len());
    println!();

    // Deploy configs for roles about to be executed
    deploy_configs::deploy_for_tags(
        &plan.tags,
        &ctx.fs,
        &ctx.local_config_root,
        &ctx.ansible,
        overwrite,
    )?;

    // Execute each tag
    for (i, tag) in plan.tags.iter().enumerate() {
        let step = i + 1;
        let total = plan.tags.len();
        println!("[{step}/{total}] Running: {tag}");

        ctx.ansible
            .run_playbook(plan.profile.as_str(), std::slice::from_ref(tag), plan.verbose)
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
    println!("  GUI Applications:  mev make brew-cask --profile {}", plan.profile);
    println!("  Ollama Models:     mev make ollama-models");
    println!("  MLX Models:        mev make mlx-models");

    Ok(())
}
