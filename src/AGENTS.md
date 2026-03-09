# mev CLI Development Context

See [root AGENTS.md](../AGENTS.md) for project overview.

## Architecture

| Layer | Path | Responsibility |
|---|---|---|
| Application | src/app/ | CLI boundary, command orchestration, dependency wiring |
| Domain | src/domain/ | Pure rules, command invariants, execution planning, interfaces |
| Ports | src/domain/ports/ | Interface boundaries (traits) required by domain/application |
| Adapters | src/adapters/ | Process execution, file I/O, catalog loading, package asset resolution |
| Assets | src/assets/ | Source-of-truth embedded static resources |
| Testing | src/testing/ | In-process test doubles and builders |
| Internal dep | crates/mev-internal/ | Internal command domain implementations reused by mev |

## app structure

- `cli/` contains clap input contracts only.
- `commands/` contains orchestration units per command domain.
- `context.rs` wires ports to adapters without command logic duplication.
- `api.rs` exposes stable library entrypoints used by `main.rs`.

## domain structure

- `error.rs` contains domain-level typed errors.
- `ports/` defines explicit interfaces consumed by application and domain.

## Development

See `justfile` for available recipes and `tests/AGENTS.md` for test execution.
