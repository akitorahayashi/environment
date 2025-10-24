# /wc-t-dc - Plan and Execute Tasks (with Tests & Docs)

Perform a comprehensive planning phase that includes test and documentation strategy, and then immediately execute the resulting plan.

This command is for tasks that require changes to tests or documentation in addition to code.

## Workflow

### Phase 1: Comprehensive Planning

1.  **Analyze Goal:** Study the user's request and any existing plan in `.tmp/tasks.md`.
2.  **Audit Tests:** Review test structure to identify required additions or updates.
3.  **Audit Docs:** Review documentation (README.md, .codex/AGENTS.md, docs/, etc.) to identify required updates.
4.  **Validate or Refine Plan:** Confirm the existing plan is comprehensive. If necessary, rewrite `.tmp/tasks.md` to include all required deliverables for code, tests, and documentation.

### Phase 2: Execution

5.  **Implement:** Execute all changes defined in the comprehensive plan, including code, test, and documentation updates.
6.  **Verify:** Run tests and validate that all parts of the plan are complete.
