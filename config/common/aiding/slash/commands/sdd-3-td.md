
## Role
QA Engineer

## Context

- Requirements, design details, and any other artefacts stored in `.tmp/`

## Your task

### 1. Review design inputs

- Rely on `.tmp/requirements.md` for the definitive scope
- Use `.tmp/design.md` when present, and skim `.tmp/minutes.md` or other notes only for supporting background

### 2. Plan the tests

- Translate the design into test coverage, considering normal, edge, and failure cases
- Note required test data, mocks, or manual checks

### 3. Record the plan

- When a test plan is needed, write `.tmp/test_design.md` using the template below so implementation knows what to verify

### 4. Share the outcome

- Point the user to `.tmp/test_design.md` if it exists
- Confirm the plan matches the current requirements
- Ask whether to continue with `/sdd-4-tk`

## Notes

Skip this step entirely when no formal testing guidance is required. Do not modify project code during this phase; confine work to documenting `.tmp/test_design.md` and related notes.

---

```markdown
# Test Specification - [Task Name]

## Test Scope
- Files to test: [list of files from design]
- Functions to test: [list of functions/methods]
- Integration points to test: [connections between components]

## Unit Tests

### Test `[file-name]`
- **Function**: `[function-name]`
- **Normal cases**: [what should work]
- **Error cases**: [what should fail and how]
- **Edge cases**: [boundary conditions]

### Test `[another-file]`
- **Function**: `[function-name]`
- **Normal cases**: [what should work]
- **Error cases**: [what should fail and how]

## Integration Tests
- **Test**: [component A] + [component B]
- **Scenario**: [what workflow to test]
- **Expected**: [what should happen]

## Test Data
- **Valid data**: [examples]
- **Invalid data**: [examples]
- **Mock responses**: [if external APIs involved]

## Manual Testing
- **User workflow**: [steps to test manually]
- **Expected behavior**: [what user should see]

## CI/CD Integration (if applicable)
- **CI suitability**: [whether these tests can run in CI environment]
- **Existing commands**: [make/just commands that already include test execution]
- **Workflow changes**: [none needed if wrapped in existing commands vs new CI steps]
- **Manual-only tests**: [tests requiring human verification or complex setup]
```
