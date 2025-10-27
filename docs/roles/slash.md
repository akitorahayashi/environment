# Slash Role

The `slash` role regenerates AI slash commands and installs prompt material used by Claude, Gemini, and Codex CLIs.

## Tag
- `slash`

Run via `just slash`. The `just nodejs` recipe also calls it after installing AI CLIs.

## Tasks
- Ensure the generator scripts (`claude.py`, `gemini.py`, `codex.py`) under `ansible/scripts/slash/` are executable.
- Execute each generator script from the repository root to rebuild slash command payloads. The commands run in a stable order and are treated as idempotent (`changed_when: false`).
- Create `~/.local/slash` and symlink `ansible/roles/slash/config/common/commands` into `~/.local/slash/commands` with `force: true`.

## Configuration
- `config/common/config.json` maps slash command identifiers to prompt files.
- Prompt files live under `config/common/commands/`, organized by feature (e.g., `sdd/`, `w/`).

Regenerate slash commands whenever prompts change by running `just slash`.
