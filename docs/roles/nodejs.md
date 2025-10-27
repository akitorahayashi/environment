# Node.js Role

The `nodejs` role provisions a Node.js toolchain alongside AI-focused CLIs that depend on it.

## Tags
- `nodejs-platform`
- `nodejs-tools`
- `claude`
- `gemini`
- `codex`

`just nodejs` runs the platform and tools tags, then delegates to `just claude`, `just gemini`, and `just codex`. The slash commands themselves are managed by the separate [slash role](./slash.md).

## Platform Tasks
- Read the Node version from `ansible/roles/nodejs/config/common/.nvmrc`.
- Install `nvm`, `jq`, and `pnpm` via Homebrew.
- Use `nvm install <version>` (with `--skip-existing`) and set the version as the default alias.

## Global Packages
- Parse `global-packages.json` and combine `dependencies` and `globalPackages` entries into a single list.
- Install each package via `pnpm install -g <package>@latest` using the default Node version and PNPM home (`~/Library/pnpm`).
- Symlink `md-to-pdf-config.js` to `$HOME/.md-to-pdf-config.js`.

## AI CLIs
- **Claude (`tasks/claude.yml`):** Install `@anthropic-ai/claude-code`, create `~/.claude`, symlink `claude.json` and `AGENTS.md`, and provision a `commands` directory for slash prompts.
- **Gemini (`tasks/gemini.yml`):** Install `@google/gemini-cli`, create `~/.gemini`, symlink settings and agent docs, warn if the CLI is unavailable, and prepare a commands directory.
- **Codex (`tasks/codex.yml`):** Install `@openai/codex`, ensure `~/.codex` and `~/.codex/prompts` exist, copy `codex.toml`, and symlink the shared `AGENTS.md` reference.

By centralizing Node installation through `nvm`, the role keeps CLIs and JavaScript tooling aligned with the project’s desired version.
