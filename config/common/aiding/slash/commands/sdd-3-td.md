
## Context

- Design: `.tmp/design.md`

## Your task

### 1. Read design document

Read the implementation instructions to understand what needs to be tested.

### 2. Create test specification

Create `.tmp/test_design.md` using the template structure shown below.

## Notes

Keep tests focused on the specific implementation - test what was designed, not everything possible.

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

### 3. Present to user

Show the test specification and provide task ID:
- Location: `.tmp/test_design.md`
- Does this cover the important test cases?
- Any missing scenarios?
- Ready for task breakdown? (use `/sdd-4-tk`)
