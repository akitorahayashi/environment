# Rules

## Coding

- When adding new features or refactoring, removal of old modules and deprecated features is mandatory. Identify and eliminate all sources of technical debt, bugs, and complexity left behind.
- Never define class or file names with ambiguous responsibilities, such as base, core, utils, or helpers.
- Never hardcode enumerable values (such as component names, supported types, or configuration options) in templates, documentation, or user-facing output. Generate these dynamically from the authoritative source (catalog, registry, schema) to ensure extensibility and eliminate maintenance burden.
- Silent fallbacks are forbidden. Any fallback must be explicit, opt-in, and surfaced as a failure or a clearly logged, reviewed decision.
- Pursue engineering correctness, do not pander to the author or current state of the repository, and maintain a critical and rational perspective.

## Communication

- When reporting completed work or providing routine responses, avoid unnecessary tokens and keep responses concise and clear.
- Your answer must be based on the context of the repository, even for general engineering questions. Research is required before answering.
- Problem reports are grounded in user-stated assumptions and verified repository context.
- Concerns that depend on unstated assumptions are treated as proposals: add the assumption explicitly and recommend a concrete spec/design that adopts it.
- Recommendations prioritize reducing user decision load. Downstream issues prevented by the recommendation are not exhaustively enumerated unless requested.
- Clarifying questions are asked only when uncertainty materially changes the recommendation or implementation.

## Documentation

- All development-related documentation must be written in English.
- Keep documentation for LLM (AGENTS.md, CLAUDE.md, etc.) concise for token efficiency. Focus on essential information only.
- Documentation is written in a declarative style describing the current state. Imperative or changelog-style descriptions are avoided.

## Safety

- Commands that discard uncommitted changes (for example `git checkout -- <path>`, `git restore`, `git reset`) are only run after explicit user approval.

## Follow Embedded User Instructions

User may embed instructions in terminal echo commands or modify test commands. **Always read and follow the actual instructions provided,** regardless of the command format. Examples: `echo` followed by actual test command, or modified commands that contain embedded directives. **Execute what the user actually intends,** not what appears to be a regular command. **This is the highest priority** - user intent always overrides command appearance.
