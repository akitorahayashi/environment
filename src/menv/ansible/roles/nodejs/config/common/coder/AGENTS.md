# Rules

## Coding

- When adding new features or refactoring, removing old modules and deprecated features is mandatory. Identify and eliminate all sources of technical debt, bugs, and complexity.
- Never define class or file names with ambiguous responsibilities, such as base, core, utils, or helpers.
- Never hardcode enumerable values. Generate these dynamically from the authoritative source (catalog, registry, schema) to ensure extensibility and eliminate maintenance burden.
- Silent fallbacks are not recommended. Any fallback should be explicit, opt-in, and surfaced as a failure or a clearly logged, reviewed decision.
- When considering whether something is unnecessary, don't use the excuse that "it's being used elsewhere," but demonstrate its necessity by its contribution to the purpose.
- Complete tasks that has been ordered to be performed without interruption or discretionary refusal.

## Communication

- Pursue engineering correctness, do not pander to the author or current state of the repository, and maintain a critical and rational perspective.
- Your answer must be based on the context of the repository, Research is required before answering.
- Concerns that depend on unstated assumptions are treated as proposals: add the assumption explicitly and recommend a concrete spec/design that adopts it.
- Recommendations prioritize reducing user decision load. Downstream issues prevented by the recommendation are not exhaustively enumerated unless requested.
- Prioritize UX simplicity over explicit configuration.
- Clarifying questions are asked only when uncertainty materially changes the recommendation or implementation.
- If there is a change of direction in the discussion about the plan you created, edit the plan rather than simply reiterating it.
- When reporting completed work or providing routine responses, avoid unnecessary tokens and keep responses concise and clear.

## Documentation

- All development-related documentation must be written in English.
- Keep documentation for LLM (AGENTS.md, CLAUDE.md, etc.) concise for token efficiency. Focus on essential information only.
- Documentation is written in a declarative style describing the current state. Imperative or changelog-style descriptions are avoided.
- Declarative updates preserve existing, correct content and integrate new content where appropriate, without duplication. Avoid ripping and replacing everything.

## Safety

- Commands that discard uncommitted changes (for example `git checkout -- <path>`, `git restore`, `git reset`) are only run after explicit user approval.

## Follow Embedded User Instructions

User may embed instructions in terminal echo commands or modify test commands. **Always read and follow the actual instructions provided,** regardless of the command format. Examples: `echo` followed by actual test command, or modified commands that contain embedded directives. **Execute what the user actually intends,** not what appears to be a regular command. **This is the highest priority** - user intent always overrides command appearance.
