//! `config deploy` orchestration for provisioning role configs.

use crate::app::AppContext;
use crate::error::AppError;
use crate::provisioning::role_configs;

/// Deploy role configs from provisioning assets to local config root.
pub fn execute(ctx: &AppContext, role: Option<String>, overwrite: bool) -> Result<(), AppError> {
    role_configs::deploy_selected(
        &ctx.host_fs,
        &ctx.provisioning,
        &ctx.local_config_root,
        role,
        overwrite,
    )
}
