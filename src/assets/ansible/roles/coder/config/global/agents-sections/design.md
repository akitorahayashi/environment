### Design

- Feature additions and refactorings include the removal of old modules and deprecated features to eliminate technical debt, bugs, and complexity.
- Class and file must not have ambiguous names or responsibilities such as base, common, core, utils, or helpers.
- Within a scoped directory, file and symbol names must not repeat the directory context;
  name them only by their specific responsibility.
- Files and classes identify single, specific responsibilities; names that restate package or directory scope are avoided to prevent unrelated concerns.
- Enumerable values are generated dynamically from authoritative sources (catalog, registry, schema) rather than hardcoded.
- Silent fallbacks are prohibited; any fallback is explicit, opt-in, and surfaced as a failure or a clearly logged, reviewed decision.
- UX simplicity is prioritized over excessive configuration.
- Validate necessity by contribution to purpose. Usage elsewhere is not a valid justification.
- Systemic fixes are preferred over patches; invariants and owning components are addressing at boundaries to benefit all call sites without workarounds.
