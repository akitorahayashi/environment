# Rules

### Design

- Feature additions and refactorings include the removal of old modules and deprecated features to eliminate technical debt, bugs, and complexity.
- Class and file must not have ambiguous names or responsibilities such as base, common, core, utils, or helpers.
- Files and classes identify single, specific responsibilities; names that restate package or directory scope are avoided to prevent unrelated concerns.
- Enumerable values are generated dynamically from authoritative sources (catalog, registry, schema) rather than hardcoded.
- Silent fallbacks are prohibited; any fallback is explicit, opt-in, and surfaced as a failure or a clearly logged, reviewed decision.
- UX simplicity is prioritized over excessive configuration.
- Validate necessity by contribution to purpose. Usage elsewhere is not a valid justification.
- Systemic fixes are preferred over patches; invariants and owning components are addressing at boundaries to benefit all call sites without workarounds.

### Implementation

- Post-implementation inventorying (git status, git diff, etc.) is avoided; only evidential verification (testing, etc.) is performed.
- Validation focuses on the appropriate scope, providing minimal evidence unless intent dictates otherwise.
- When renaming, deleting, or restructuring, a comprehensive search (e.g., `rg`) for the old structure or terms must be performed at the end to ensure no remnants are left behind.

### Testing

- Tests assert externally observable behavior at the owning boundary.
- A behavior is part of the test contract only when the boundary explicitly owns it.
- Tests do not freeze internal composition choices such as file placement, includes, wording, generated layout, or responsibility splits between nearby modules unless those are the observable behavior owned by the boundary.
- Rename, deletion, and restructuring residue checks belong to implementation-time search, not durable tests, unless legacy handling is itself an explicit contract.
- Temporary operations are confined to the project root unless external constraints apply (e.g., use `./.tmp/` instead of `/tmp/`).

### Documentation

- Development-related documentation is written in English.
- Documentation for LLMs (AGENTS.md, CLAUDE.md, etc.) is kept concise for token efficiency, focusing only on essential information.
- Documentation is written in a declarative style describing the current state. Imperative or changelog-style descriptions are prohibited.
- Declarative updates preserve existing content and integrate new material without duplication or complete replacement.
- The documentation must conform to the implementation, and the implementation must not be modified to conform to the documentation.
- Do not use bold emphasis (**) in Markdown. Use hierarchy and headings for organization.

### Communication

- Base responses on repository context. Research is mandatory at conversation start.
- Prefer concise, well-structured replies over verbose responses.
- Replies start with the direct answer to the user's question.
- Intent narration and conditional offers (for example, "I will...", "If needed...") are avoided; either deliver the result now or ask the single blocking question.
- Pursue engineering correctness; do not pander to the current repository state or the author.
- Treat unstated assumptions as proposals: state the assumption explicitly and proceed with a concrete design, or ask for confirmation when it is a real blocker.
- Critique includes a concrete replacement (patch, rewritten text, command, or decision) in the same message.
- Do not consider or comment on issues that have already been resolved.

### Safety

- Commands that discard uncommitted changes (for example `git checkout -- <path>`, `git restore`, `git reset`) are only run after explicit user approval.

## User-specific

- `.mx/*.md` files are context-file storage. Read only upon explicit instruction.
