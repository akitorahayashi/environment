//! `create` command orchestration — full environment setup.

use std::process::Stdio;
use std::thread;

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::execution_order;
use crate::provisioning::execution_plan::{ExecutionUnit, LayeredExecutionPlan};
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

    for (layer_index, layer) in plan.layers.iter().enumerate() {
        let layer_number = layer_index + 1;
        println!("Layer {layer_number}/{}:", plan.layer_count());
        println!(
            "  Running: {}",
            layer.iter().map(|unit| unit.name.as_str()).collect::<Vec<_>>().join(", ")
        );

        let mut results = Vec::with_capacity(layer.len());
        thread::scope(|scope| {
            let mut handles = Vec::with_capacity(layer.len());
            for unit in layer {
                let unit_name = unit.name.clone();
                let unit_tags = unit.ansible_tags.clone();
                handles.push(scope.spawn(move || {
                    (
                        unit_name,
                        run_playbook_summarized(
                            &ctx.provisioning,
                            plan.profile.as_str(),
                            &unit_tags,
                            plan.verbose,
                        ),
                    )
                }));
            }

            for handle in handles {
                results.push(handle.join().expect("layer execution thread panicked"));
            }
        });

        if let Some((failed_unit, error)) =
            results.into_iter().find_map(|(name, result)| result.err().map(|err| (name, err)))
        {
            eprintln!(
                "Failed at layer {layer_number}/{}: {failed_unit}: {error}",
                plan.layer_count()
            );
            return Err(error);
        }

        println!("  ✓ Completed");
    }

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

fn run_playbook_summarized(
    runtime: &crate::provisioning::ansible_runtime::AnsibleRuntime,
    profile: &str,
    tags: &[String],
    verbose: bool,
) -> Result<(), AppError> {
    let mut cmd = runtime.build_command(profile, tags, verbose)?;
    cmd.stdout(Stdio::piped());
    cmd.stderr(Stdio::piped());

    let output = cmd.output().map_err(|e| AppError::AnsibleExecution {
        message: format!("failed to run ansible-playbook: {e}"),
        exit_code: None,
    })?;

    if output.status.success() {
        return Ok(());
    }

    let exit_code = output.status.code();
    let summary = capture_failure_summary(&output.stdout, &output.stderr);

    Err(AppError::AnsibleExecution {
        message: match summary {
            Some(line) => format!(
                "ansible-playbook failed{}; reason: {line}",
                exit_code.map(|code| format!(" with exit code {code}")).unwrap_or_default()
            ),
            None => format!(
                "ansible-playbook failed{}",
                exit_code.map(|code| format!(" with exit code {code}")).unwrap_or_default()
            ),
        },
        exit_code,
    })
}

fn capture_failure_summary(stdout: &[u8], stderr: &[u8]) -> Option<String> {
    let stdout = String::from_utf8_lossy(stdout);
    let stderr = String::from_utf8_lossy(stderr);

    stdout
        .lines()
        .chain(stderr.lines())
        .map(str::trim)
        .find(|line| {
            line.starts_with("fatal:") || line.contains("cannot rehash") || line.contains("FAILED!")
        })
        .map(ToOwned::to_owned)
}
