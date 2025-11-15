# /wc-t - Work on tasks critically (with Tests)

Perform a comprehensive planning phase that includes test strategy, and then immediately execute the resulting plan.

This command is for tasks that require changes to tests in addition to code.

**Important:** Ensure the entire workflow completes fully without premature termination. Do not stop mid-phase; complete all steps in each phase before proceeding.

## Workflow

### Phase 1: Comprehensive Planning

1.  **Analyze Goal:** Study the user's request and any existing plan in `.tmp/tasks.md`.
2.  **Critically Review Scope:** Critically review the scope of edits needed, considering what might be missing in the plan, and ensure sufficient editing is contemplated for the goal.
3.  **Audit Tests:** Review test structure to identify required additions or updates.
4.  **Create Revised Plan:** Create `.tmp/revised_tasks.md` to include all required deliverables for code and tests.

### Phase 2: Execution

4.  **Implement:** Execute all changes defined in the comprehensive plan, including code and test updates. Complete the entire implementation without interruption before moving to verification.
5.  **Verify:** Run tests and validate that all parts of the plan are complete.