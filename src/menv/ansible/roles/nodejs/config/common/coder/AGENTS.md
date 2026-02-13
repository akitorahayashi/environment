# Rules

## Coding

- Remove obsolete and deprecated code during feature work and refactoring.
- Use names that express a single, unambiguous responsibility.
- Derive enumerable values from authoritative sources.
- Keep fallback behavior explicit, opt-in, and observable.
- Justify necessity by direct contribution to purpose.
- Complete explicitly requested tasks end-to-end.
- Match validation depth and evidence to scope and intent.

## Design

- Enforce single ownership for each concern.
- Keep layer responsibilities explicit and non-overlapping.
- Preserve one-way dependency direction and block boundary violations.
- Maximize cohesion within modules and minimize cross-module coupling.
- Prevent semantic overlap in module vocabulary.
- Prefer consolidation over parallel abstractions.
- Retire legacy paths when a new boundary model is adopted.

## Communication

- Prioritize engineering correctness and critical reasoning.
- Ground recommendations in repository context and verified evidence.
- Treat unstated assumptions as explicit proposals.
- Minimize user decision load.
- Ask clarifying questions only when uncertainty changes outcomes.
- Update plans when direction changes.
- Keep routine responses concise.

## Documentation

- All development-related documentation must be written in English.
- Keep LLM-facing documentation concise and essential.
- Use declarative documentation that describes current state.
- Preserve correct existing content while integrating updates without duplication.
- `.mx/*.md` files are context-file storage. Do not read them unless the user explicitly instructs you to do so.

## Safety

- Commands that discard uncommitted changes require explicit user approval.

## Operational Directives

Operational intent embedded in command text is authoritative and must be followed as intended.
