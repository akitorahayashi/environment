use std::thread;

use crate::error::AppError;
use crate::provisioning::ansible_runtime::AnsibleRuntime;
use crate::provisioning::execution_plan::ExecutionUnit;

/// Run a layered provisioning plan and emit compact layer progress.
pub(crate) fn run_layered_playbook(
    runtime: &AnsibleRuntime,
    profile: &str,
    layers: &[Vec<ExecutionUnit>],
    verbose: bool,
) -> Result<(), AppError> {
    for (layer_index, layer) in layers.iter().enumerate() {
        let layer_number = layer_index + 1;
        println!("Layer {layer_number}/{}:", layers.len());
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
                        unit_name.clone(),
                        run_playbook_summarized(runtime, profile, &unit_name, &unit_tags, verbose),
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
            eprintln!("Failed at layer {layer_number}/{}: {failed_unit}: {error}", layers.len());
            return Err(error);
        }

        println!("  ✓ Completed");
    }

    Ok(())
}

pub(crate) fn run_playbook_summarized(
    runtime: &AnsibleRuntime,
    profile: &str,
    label: &str,
    tags: &[String],
    verbose: bool,
) -> Result<(), AppError> {
    let output = runtime.run_playbook_captured(profile, tags, verbose)?;

    if output.status.success() {
        return Ok(());
    }

    let exit_code = output.status.code();
    let summary = capture_failure_summary(&output.stdout, &output.stderr);
    emit_captured_output(label, &output.stdout, &output.stderr);

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

fn emit_captured_output(label: &str, stdout: &[u8], stderr: &[u8]) {
    let stdout = String::from_utf8_lossy(stdout);
    let stderr = String::from_utf8_lossy(stderr);

    if !stdout.trim().is_empty() {
        eprintln!("--- {label} stdout ---");
        eprintln!("{}", stdout.trim_end());
    }

    if !stderr.trim().is_empty() {
        eprintln!("--- {label} stderr ---");
        eprintln!("{}", stderr.trim_end());
    }
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
