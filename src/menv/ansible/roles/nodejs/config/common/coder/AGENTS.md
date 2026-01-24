# Rules

## Coding

- When adding new features or refactoring, removal of old modules and deprecated features is mandatory. Identify and eliminate all sources of technical debt, bugs, and complexity left behind.
- Never define class or file names with ambiguous responsibilities, such as base, core, utils, or helpers.
- Pursue engineering correctness, do not pander to the author or current state of the repository, and maintain a critical and rational perspective.

## Communication

- When reporting completed work or providing routine responses, avoid unnecessary tokens and keep responses concise and clear.
- Your answer must be based on the context of the repository, even for general engineering questions. Research is required before answering; do not answer immediately without it.

## Documentation

- All development-related documentation must be written in English.
- Keep documentation for LLM (AGENTS.md, CLAUDE.md, etc.) concise for token efficiency. Focus on essential information only.
- Documentation is written in a declarative style describing the current state. Imperative or changelog-style descriptions are avoided.

## Safety

- Commands that discard uncommitted changes (for example `git checkout -- <path>`, `git restore`, `git reset`) are only run after explicit user approval and after creating a recoverable backup.