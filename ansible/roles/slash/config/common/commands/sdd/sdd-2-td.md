# Plan Tests Design

## Role

QA Engineer

## Context

- `.tmp/requirements.md` is the authoritative source defining what needs to be built
- Design details and other artefacts stored in `.tmp/`

## Your task

### 1. Review design inputs

- Rely on `.tmp/requirements.md` for the definitive scope
- Use `.tmp/design.md` when present, and review other notes in `.tmp/` only for supporting background

### 2. Investigate existing test structure

- Examine current testing practices (test frameworks, naming conventions, CI setup)
- Identify existing test suites, scripts, and CI jobs that may already cover related functionality
- Understand the project's testing culture and conventions

### 3. Plan the tests

- **Respect project testing culture**: Adapt to existing testing patterns; skip formal test planning when project has minimal testing practices
- Map requirements to existing suites, scripts, and CI jobs
- Call out only the additional coverage that is actually needed (leave a note when no new tests are required)
- Note required test data, mocks, or manual checks when they are not already covered elsewhere

### 4. Record the plan

- Capture the outcome in `.tmp/test_design.md`, referencing the template below and pruning sections that do not apply
- Documentation only; do not modify project code during this phase

---

```markdown
# Test Specification - [Task Name]

> Tailor this outline to the real scope. Remove sections that do not apply and point to existing assets whenever possible.

## Test Scope
- **Focus areas**: [features or flows covered by this work]
- **Existing coverage**: [suites/commands/pipelines already exercising this area]
- **Net-new coverage**: [only if additional tests are required]

## Unit / Component Tests *(include only when new or changed)*
- **Suite/command**: [`just test-module`]
  - **Target**: [file/function]
  - **Notes**: [normal/error/edge cases still missing]

## Integration / End-to-End *(include only when new or changed)*
- **Workflow**: [component A ↔ component B]
  - **Validation**: [how to observe success/failure]
  - **Reuse**: [existing script or playbook name]

## Manual / Exploratory *(optional)*
- **Scenario**: [user journey or system state]
- **Steps**: [how to execute]
- **Expected**: [observable outcome]

## Automation & CI Hooks
- **Current pipeline**: [`just ci`, `gh workflow run build.yml`, etc.]
- **Adjustments**: [none if existing structure already covers it]
- **Follow-up**: [backlog items or risks when coverage stays manual]

## Test Data & Fixtures *(only when not already available)*
- **Source**: [file, script, or dataset]
- **Preparation steps**: [how to set up data/mocks]
```