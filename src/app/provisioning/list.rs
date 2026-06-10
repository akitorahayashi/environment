//! `list` command orchestration — display tags, groups, and profiles.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::profile;

/// Execute the `list` command: print tags, groups, and profiles.
pub fn execute(ctx: &AppContext) -> Result<(), AppError> {
    let tags_map = ctx.provisioning.tags_by_role();

    let mut roles: Vec<_> = tags_map.iter().collect();
    roles.sort_by_key(|&(name, _)| name);
    let role_width = roles.iter().map(|(name, _)| name.len()).max().unwrap_or(0).max(4);

    // Role -> tags table
    println!("Available Tags");
    println!("{:<role_width$} Tags", "Role");
    println!("{:-<role_width$} {:-<40}", "", "");
    for (role, tags) in &roles {
        println!("{:<role_width$} {}", role, tags.join(", "));
    }
    println!();

    // Tag groups
    println!("Tag Groups (expanded automatically):");
    let groups = ctx.provisioning.tag_groups();
    let mut group_keys: Vec<_> = groups.keys().collect();
    group_keys.sort();
    for key in group_keys {
        let tags = &groups[key];
        println!("  {key} -> {}", tags.join(", "));
    }
    println!();

    // Profiles
    let profile_strs: Vec<String> = profile::all_profiles()
        .iter()
        .map(|p| {
            let aliases = p.aliases();
            let alias_str = if aliases.is_empty() {
                String::new()
            } else {
                format!(" ({})", aliases.join(", "))
            };
            let suffix = if matches!(p, profile::Profile::Global) { " (default)" } else { "" };
            format!("{p}{alias_str}{suffix}")
        })
        .collect();
    println!("Profiles: {}", profile_strs.join(", "));

    Ok(())
}
