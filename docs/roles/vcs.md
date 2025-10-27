# VCS Role

The `vcs` role configures Git and Jujutsu (JJ) so both tools share consistent settings across machines.

## Tags
- `git`
- `jj`

Use `just git` or `just jj` to target individual tools; both run as part of `just common`.

## Git Tasks
Defined in `tasks/git.yml`:
- Install Git via Homebrew.
- Ensure `$HOME/.config/git` exists and copy `config/common/git/.gitconfig` to `$HOME/.config/git/config`.
- Symlink `config/common/git/.gitignore_global` to `$HOME/.gitignore_global` and set `core.excludesfile` globally.

## JJ Tasks
Defined in `tasks/jj.yml`:
- Install `jj` via Homebrew.
- Create `$HOME/.jj`, `$HOME/.config/jj`, and `$HOME/.config/jj/conf.d`.
- Copy `config/common/jj/config.toml` and the supporting `conf.d` snippets into place.

## Profile Switching
The Just recipes `just sw-p` and `just sw-w` layer on top of this role by updating Git and JJ identities using variables from `.env`. Run them whenever you need to swap profiles.
