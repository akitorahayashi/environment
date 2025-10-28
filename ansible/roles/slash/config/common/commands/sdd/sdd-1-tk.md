# Plan Implementation & Tasks

## Role

Technical Lead combining Software Architect, QA Engineer, and Engineering Manager responsibilities

## Your Task

### 1. Design the Solution

- Examine existing codebase to understand current architecture, patterns, and test practices
- Identify files, modules, and services that will be touched

**Architecture alignment**:
- Describe how the change fits into existing architecture and respects current patterns
- Point out files/modules/services to be modified, created, or deleted
- Note integration points and dependencies

**Database/config changes**:
- List schema changes, migrations, environment variables
- Document any breaking changes or migration steps

### 2. Plan Test Coverage

**Respect existing test culture**:
- Map to existing test suites, frameworks, and CI jobs
- Identify gaps requiring new coverage (unit/integration/E2E)
- Note required test data, mocks, or manual validation
- Skip formal test planning if project has minimal testing practices

### 3. Break Down Tasks

**Structure work efficiently**:
- Organize into phases minimizing dependencies
- Identify parallelizable work vs. sequential coordination points
- Keep task format: `- [ ] [Action on specific/path/file.ext]`

**Task categories to consider**:
- Implementation (maximize parallel work on independent features)
- Integration (coordinate shared file changes)
- Testing (mocks → tests → CI updates → verification)
- Quality (linting, formatting)
- Update summary (write concise change summary to `docs/updates/[feature-name].md`)

### 4. Create `.tmp/sdd/tasks.md`

Write a consolidated task breakdown using the template below.

## Notes

- Do not write code during this planning phase—outputs stay in `.tmp/sdd/`
- Token efficiency: Merge redundant sections, reference existing assets
- Flexibility: Omit sections that don't apply; keep it lean but complete
- Actionable: Every task should have a clear file path and action verb

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built

---

## Template

```markdown
# Implementation Plan - [Task Name]

## Design Overview

### Approach
[Brief summary of solution and chosen strategy]

### Files to Change

#### Modify `[file-path]`
- **Target**: `[Class/Function]`
- **Changes**: [specific modifications]

#### Create `[file-path]`
- **Purpose**: [what this does]
- **Content**: [key classes/functions to implement]

#### Delete `[file-path]`
- **Reason**: [why obsolete]
- **Dependencies**: [files to update]

### Integration Points
- [Component A ↔ Component B interactions]

### Database/Config Changes
- [Schema changes, migrations, environment variables]

### Documentation Updates
- [Existing documentation files requiring updates: README.md, AGENTS.md, docs/*]
- [Only update existing documentation—never create new files or directories]

## Test Strategy

### Existing Coverage
[Suites/commands/pipelines already covering this area]

### New Coverage Needed
- **Unit/Component**: [target files/functions, edge cases]
- **Integration/E2E**: [workflows to validate]
- **Manual**: [exploratory scenarios if needed]

### Test Data & Mocks
[Required fixtures, mock setup, data preparation]

### CI Integration
[Pipeline adjustments, automation hooks]

## Task Breakdown

### Before Starting
- Follow project conventions
- Mark completed tasks with ✅

### Phase 1: [Name]
**Goal**: [Objective]
- [ ] [Task with file path]
- [ ] [Task with file path]

### Phase 2: [Name]
**Goal**: [Objective]
- [ ] [Task with file path]
- [ ] [Task with file path]

### Phase 3: Quality & Review
- [ ] Run linter/formatter on changed files
- [ ] Verify tests pass (respect project testing culture - skip if minimal testing practices)
- [ ] Review and commit changes

## Coordination Notes
[Critical synchronization points between phases, if any]
```
