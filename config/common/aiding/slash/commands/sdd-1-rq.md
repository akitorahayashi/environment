
## Context

- Task description: {args}

## Your task

### 1. Create task directory

- Generate sequential task ID (e.g., 01, 02, 03, etc.)
- Create `.tmp/task[id]/` directory (e.g., .tmp/task01/, .tmp/task02/)
- All SDD outputs for this task will go in this directory

### 2. Quick analysis

Understand the core request:
- What needs to be built?
- Who will use it?
- What's the main benefit?

### 3. Create simple requirements

Create `.tmp/task[id]/requirements.md`:

```markdown
# Requirements - [Task Name]

## Goal
[What we want to achieve in 1-2 sentences]

## Users
- [Who will use this]

## Must Have
- [ ] [Essential feature 1]
- [ ] [Essential feature 2]
- [ ] [Essential feature 3]

## Nice to Have
- [ ] [Optional feature 1]
- [ ] [Optional feature 2]

## Success
- [How we know it's done]

## Notes
- [Any important constraints or considerations]
```

## Notes

Focus only on business requirements - don't worry about project structure, technical implementation, or existing codebase. Keep it purely business-focused.