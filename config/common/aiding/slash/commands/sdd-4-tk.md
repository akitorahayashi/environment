
## Context

- Task ID: {args} (e.g., 01, 02, 03)
- Design: `.tmp/task{args}/design.md`
- Test spec: `.tmp/task{args}/test_design.md`

## Your task

### 1. Read implementation design

Understand the specific files and changes needed from the design document.

### 2. Create task breakdown

Create `.tmp/task{args}/tasks.md`:

```markdown
# Task Breakdown - [Task Name]

## Overview
- Total tasks: [number]
- Estimated time: [hours]

## Implementation Tasks

### 1. Create/Modify `[file-name]`
- [ ] Create new file `[file-path]`
- [ ] Add class `[ClassName]` with methods `[method1]`, `[method2]`
- [ ] Implement `[specific-functionality]`
- **Time**: [hours]

### 2. Update `[config-file]`
- [ ] Add environment variable `[VAR_NAME]`
- [ ] Update configuration section `[section-name]`
- **Time**: [hours]

### 3. Database Changes
- [ ] Create migration file `[migration-name]`
- [ ] Add table `[table-name]` with columns
- [ ] Run migration
- **Time**: [hours]

### 4. Integration
- [ ] Update `[file-name]` to call new `[method-name]`
- [ ] Test integration between components
- **Time**: [hours]

### 5. Testing
- [ ] Write unit tests for `[component]`
- [ ] Write integration tests
- [ ] Manual testing of user workflow
- **Time**: [hours]

### 6. Documentation
- [ ] Update README if needed
- [ ] Add code comments
- [ ] Update API documentation
- **Time**: [hours]

## Order
1. Do tasks 1-3 first (core implementation)
2. Then task 4 (integration)
3. Finally tasks 5-6 (testing and docs)
```

### 3. Present to user

Show the task breakdown and provide task ID:
- Task ID: {args}
- Location: `.tmp/task{args}/tasks.md`
- Tasks are ready for implementation
- Start with task 1 and work in order
- Ready for documentation integration? (use `/sdd-5-dc {args}`)

## Notes

Create specific, actionable tasks that can be completed in 1-4 hours each. Focus on the exact implementation steps from the design.