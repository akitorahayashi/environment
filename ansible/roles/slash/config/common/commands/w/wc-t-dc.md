# /wc-t-dc - Work on tasks critically (with Tests & Docs)

Perform a comprehensive planning phase that includes test and documentation strategy, and then immediately execute the resulting plan.

This command is for tasks that require changes to tests or documentation in addition to code.

**Important:** Ensure the entire workflow completes fully without premature termination. Do not stop mid-phase; complete all steps in each phase before proceeding.

## Workflow

### Phase 1: Comprehensive Planning

1.  **Analyze Goal:** Study the user's request and any existing plan in `.tmp/tasks.md`.
2.  **Critically Review Scope:** Critically review the scope of edits needed, considering what might be missing in the plan, and ensure sufficient editing is contemplated for the goal.
3.  **Audit Tests:** Review test structure to identify required additions or updates.
4.  **Identify Documentation:** Determine which existing documentation (README.md, AGENTS.md, docs/) will need updates—follow project documentation culture.
5.  **Create Revised Plan:** Create `.tmp/revised_tasks.md` to include all required deliverables for code, tests, and documentation.

### Phase 2: Execution

5.  **Implement:** Execute all changes defined in the comprehensive plan, including code, tests, and documentation updates. Complete the entire implementation without interruption before moving to verification.
6.  **Verify:** Run tests and validate that all parts of the plan are complete.
