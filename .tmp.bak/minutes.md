## 2024-10-?? SDD Session
### Current Status Analysis
- Reviewed requirement: extend `ansible/roles/mcp/tasks/main.yml` to sync MCP settings from `~/.codex/config.toml` into `config/common/aiding/codex/config.toml` when source exists.
- Inspected existing Ansible task: file currently copies `config/common/mcp/servers.json` to `~/.mcp.json`.
- Loaded MCP server definitions from `config/common/mcp/servers.json` for reference.
- Attempted to consult `config.md` (lines 339-376) as referenced; file not present in repo (lookup via `find`); noted as unavailable input.
- Located `config/common/aiding/codex/config.toml`; currently defines default model metadata with no `mcp_servers` section.
- Reviewed relevant `justfile` recipes: `cmn-codex` triggers NodeJS/Codex Ansible role, `cmn-mcp` triggers MCP role; order sensitivity identified by requester.

### Problem Digging
- Key objective: ensure repository-level Codex config mirrors any locally-specified MCP servers so Ansible-managed config remains authoritative.
- Constraints: sync happens only when `~/.codex/config.toml` exists; repository should avoid overwriting with stale data when absent.
- Potential dependency: MCP role may assume Codex role ran first to create base config file; need to respect this in procedural guidance (e.g., `just cmn-codex` before `just cmn-mcp`).
- Missing documentation (`config.md`) introduces ambiguity around exact schema; must infer from provided format snippet and existing JSON definitions.

### Solution Search
- Option A: Use Ansible `stat` + `slurp` to read `~/.codex/config.toml`, parse as TOML via `community.general.toml` filter (requires ensuring collection available), then merge `mcp_servers` data with repo file and write output using `copy` or `template`. Pros: stays inside YAML tasks; cons: requires filter availability, more complex.
- Option B: Delegate to Ansible `command`/`shell` running a small Python script to perform TOML merge. Pros: more control over TOML structure; cons: exec dependency, less idempotent without extra care.
- Option C: Treat repository file as canonical template and simply copy local `.codex/config.toml` over it when present. Pros: simple; cons: may overwrite non-MCP settings unless we limit to `mcp_servers` block; need to confirm scope.
- Tentative approach: prefer Option A to keep Ansible-managed data minimal and avoid external scripting; will need to describe tasks: `stat` check, `slurp`, `set_fact` with `community.general.from_toml`, update `mcp_servers`, render using `community.general.to_toml` or Jinja template.
- For `justfile`, recommend chaining recipes or documenting sequencing (e.g., wrap with meta-recipe that runs codex then mcp) to guarantee prerequisites.

### Follow-up Question Analysis
- Confirmed need for fine-grained TOML edits: update only relevant `mcp_servers.*` sections while preserving other Codex settings.
- Ansible approach: `community.general.from_toml` returns native dict which can be updated per server key and converted back; alternative is templating with `community.general.toml_dumps` filter or custom Jinja logic.
- Edge consideration: must ensure iteration preserves deterministic ordering (sort keys) to keep diffs stable; may need `dict | dict2items | sort` pattern before dumping.

### Implementation Feasibility – TOML Section Updates
- Confirmed Ansible can parse and mutate TOML structures using `community.general.from_toml` and `toml_dumps` filters.
- Proposed flow: `stat` to guard existence, `slurp` + decode to dict, update `mcp_servers` map via `combine(recursive=True)`, then dump back to TOML.
- Ensures precision updates per server while preserving unrelated sections; ordering stability achievable with `dict2items | sort | items2dict` pattern.
- Requirement: ensure `community.general` collection declared so filters are available during playbook execution.

