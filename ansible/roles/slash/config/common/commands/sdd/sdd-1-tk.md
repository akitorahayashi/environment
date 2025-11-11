# Break Down Tasks

## Role

Engineering Manager

## Your task

### 1. Design phases and agent usage

- Structure the work into minimal phases; execution is sequential by a single agent.
- Use exactly one agent for the entire effort.
- The agent maintains context and ownership throughout the project.

### 2. Build `.tmp/sdd/tasks/phase_N.md` files

- Create one file per phase (e.g., `phase_1.md`, `phase_2.md`)
- Tag the single agent with a brief role description (e.g., "Agent (Backend API)")
- Use plain bullets (no checkboxes)
- No parallel work; tasks progress sequentially

## Notes

- Do not write code during this planning phase—outputs stay in `.tmp/sdd/`

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built

---

## Task Breakdown Patterns

Apply these patterns when creating phase files:

**Typical Phase Flow**:
1. Implementation → Integration → Testing (single agent, sequential)

**Fixed Final Phase** (always include):
- **Phase N: Quality & Review**: Single agent responsible for both Quality (runs linter/formatter) and General Review (reviews codebase critically against requirements and edits if permitted)

**Task Format**: `- [Action on specific/path/file.ext] (Agent: Role)`

**Phase File Template** (`.tmp/sdd/tasks/phase_N.md`):
```markdown
# Phase N: [Name]

**Goal**: [Objective]

**Tasks**:

**Agent ([Role description])**:
- [Action on specific/path/file.ext]
- [Action on specific/path/file.ext]
```

**Project Overview File** (`.tmp/sdd/tasks/overview.md`):
```markdown
# Task Breakdown Overview - [Name]

## Summary
- Total agents: 1
- Total phases: [count]

## Phase Sequence
1. Phase 1: [Name] - [Brief goal]
2. Phase 2: [Name] - [Brief goal]
...
N. Phase N: Quality & Review - Linting/formatting + critical codebase review

## Notes
- Follow project conventions
- Update existing documentation following project documentation culture
```
