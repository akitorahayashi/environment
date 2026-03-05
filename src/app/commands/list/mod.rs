//! `list` command orchestration — display tags, groups, and profiles.

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::profile;
use crate::domain::tag;

/// Execute the `list` command: print tags, groups, and profiles.
pub fn execute(ctx: &DependencyContainer) -> Result<(), AppError> {
    let tags_map = ctx.ansible.tags_by_role();

    // Role → tags table
    println!("Available Tags");
    println!("{:<20} Tags", "Role");
    println!("{:-<20} {:-<40}", "", "");
    let mut roles: Vec<_> = tags_map.iter().collect();
    roles.sort_by_key(|(name, _)| (*name).clone());
    for (role, tags) in &roles {
        println!("{:<20} {}", role, tags.join(", "));
    }
    println!();

    // Tag groups
    println!("Tag Groups (expanded automatically):");
    let groups = tag::tag_groups();
    let mut group_keys: Vec<_> = groups.keys().collect();
    group_keys.sort();
    for key in group_keys {
        let tags = &groups[key];
        println!("  {key} → {}", tags.join(", "));
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
            let suffix = if matches!(p, profile::Profile::Common) { " (default)" } else { "" };
            format!("{p}{alias_str}{suffix}")
        })
        .collect();
    println!("Profiles: {}", profile_strs.join(", "));

    Ok(())
}
