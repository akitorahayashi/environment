# Implementation Instructions - MCP Configuration Synchronization

## Overview
Introduce an Ansible-driven synchronization step that keeps the repository Codex configuration aligned with the authoritative MCP server catalogue whenever a user Codex config is present. The approach augments the MCP role to read the existing Codex TOML, replace only the `mcp_servers` section with data derived from `config/common/mcp/servers.json`, and write the result back so the symlinked user config stays consistent. Process guidance will enforce running the Codex setup before this synchronization.

## Files to Modify/Create/Delete (examples - use only what applies)

### 1. Modify `ansible/roles/mcp/tasks/main.yml`
- **Changes**:
  - Add a guarded block after the existing `.mcp.json` copy to `stat` `{{ ansible_env.HOME }}/.codex/config.toml` (following symlinks) and exit early when absent.
  - When present, `slurp` the Codex config, decode it to a dict via `community.general.from_toml`, and load MCP server definitions from `{{ config_dir_abs_path }}/mcp/servers.json`.
  - Transform the JSON entries into the TOML-friendly structure expected under `[mcp_servers.<name>]`, omitting descriptive fields not supported by Codex (retain `command`, `args`, and optional `env`/timeouts when provided).
  - Merge the new `mcp_servers` map into the decoded Codex config while preserving all other keys; ensure deterministic ordering (e.g., `dict2items | sort | items2dict`) before serialization.
  - Serialize the updated dict back to TOML using `community.general.toml_dumps` (or equivalent) and overwrite `config/common/aiding/codex/config.toml` via an idempotent `copy` with `content=` so the repo and symlinked user file remain synchronized.
  - Optionally register a fact or debug message that highlights when synchronization was skipped versus performed for visibility.

### 2. Create `ansible/roles/mcp/meta/main.yml`
- **Purpose**: Declare the `community.general` collection dependency required for TOML parsing/serialization filters.
- **Content**:
  - Set `galaxy_info` minimally (author/license if needed) and include `collections:
    - community.general` to guarantee availability during role execution.

### 3. Update `justfile`
- **Changes**:
  - Introduce a convenience recipe (e.g., `cmn-codex-mcp`) that sequentially runs `cmn-codex` then `cmn-mcp`, or document the ordering requirement inline under the existing MCP target, to codify the mandated execution order.
  - Optionally add a comment reminding maintainers that MCP sync expects the Codex symlink to exist.

### 4. Update `docs/` or relevant operations notes (if such file exists)
- **Changes**:
  - Document how the MCP server catalogue feeds into Codex configuration and the need to update `config/common/mcp/servers.json` for new servers.
  - Outline any verification or troubleshooting steps (e.g., rerunning `just cmn-codex-mcp` after catalogue changes).

## Database Changes
- None.

## Integration Points
- The new MCP synchronization block relies on the Codex role (`ansible/roles/nodejs/tasks/codex.yml`) having already established the `~/.codex/config.toml` symlink; enforce this via `justfile` ordering and role documentation.
- Ensure CI or local automation that invokes the MCP role either uses the combined recipe or otherwise guarantees Codex setup precedes it.

## Environment Setup
- If not already installed, ensure the Ansible control environment has the `community.general` collection available (`ansible-galaxy collection install community.general`).
- Communicate the new `just cmn-codex-mcp` (or documented sequence) to platform engineers so they adopt the correct workflow.

