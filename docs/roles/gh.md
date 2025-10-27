# GitHub CLI Role

The `gh` role installs and configures the GitHub CLI with project-specific aliases.

## Tag
- `gh`

Triggered by `just gh` and included in `just common`.

## Tasks
- Install `gh` via Homebrew (`community.general.homebrew`).
- Create `$HOME/.config/gh`.
- Symlink `ansible/roles/gh/config/common/config.yml` to `$HOME/.config/gh/config.yml` with `force: true`.

## Configuration Highlights
- The config file defines handy aliases such as `pr-ls`, which calls the Python helper `gh_pr_ls.py` symlinked through the shell role into `~/.menv/scripts/gh/`.
- Aliases cover repo browsing (`re-ls`), branching diff helpers (`br-df`), and automated merge checks (`pr-mr`).

Ensure `GITHUB_TOKEN` or `GH_TOKEN` is available in the environment when using aliases that hit the GitHub API.
