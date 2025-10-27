# /wc-t-dc - Plan and Execute Tasks (with Tests & Docs)

Perform a comprehensive planning phase that includes test and documentation strategy, and then immediately execute the resulting plan.

This command is for tasks that require changes to tests or documentation in addition to code.

## Workflow

### Phase 1: Comprehensive Planning

1.  **Analyze Goal:** Study the user's request and any existing plan in `.tmp/tasks.md`.
2.  **Audit Tests:** Review test structure to identify required additions or updates.
3.  **Validate or Refine Plan:** Confirm the existing plan is comprehensive. If necessary, rewrite `.tmp/tasks.md` to include all required deliverables for code and tests.

### Phase 2: Execution

4.  **Implement:** Execute all changes defined in the comprehensive plan, including code and tests.
5.  **Write Update Summary:** Create concise change summary in `docs/updates/[feature-name].md`.

**Note**: `docs/` files are reference only—do not update unless explicitly requested by user.
6.  **Verify:** Run tests and validate that all parts of the plan are complete.
