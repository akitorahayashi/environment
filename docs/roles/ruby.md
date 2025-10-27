# Ruby Role

The `ruby` role prepares a user-level Ruby toolchain managed by rbenv.

## Tag
- `ruby`

Run individually with `just ruby` or as part of `just common`.

## Tasks
- Read the desired version from `ansible/roles/ruby/config/common/.ruby-version`.
- Install `openssl` and `rbenv` via Homebrew.
- Install the requested Ruby version (`rbenv install <version> --skip-existing`) and set it as the global default.
- Install `bundler` version `2.5.22` without documentation.

This role ensures Ruby-based tooling (such as `bundler` projects) is ready without requiring system-level changes.
