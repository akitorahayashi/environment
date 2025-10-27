# Rust Role

The `rust` role installs the Rust toolchain and curated cargo binaries using `rustup` and `cargo install`.

## Tags
- `rust-platform`
- `rust-tools`

Both run when invoking `just rust`; you can target them separately with `just rust-platform` or `just rust-tools`.

## Platform Tasks
- Read the desired toolchain version from `ansible/roles/rust/config/common/.rust-version`.
- Download the official `rustup-init.sh` with a pinned checksum, install Rust in minimal profile mode, and set the requested default toolchain.
- Load extra components from `config/common/rust-components.yml` (currently `rustfmt` and `clippy`) and add them via `rustup component add`.

## Tool Tasks
- Load cargo tools from `config/common/tools.yml` (supports git-based crates and custom tags).
- Install each tool with `cargo install --force`, respecting git repositories and tags.
- Clean cargo caches (`registry/cache`, `registry/src`, `git/checkouts`) to minimize leftover artifacts on developer machines.

Re-run `just rust` after editing tool lists to install updates.
