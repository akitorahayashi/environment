
## Role
Engineering Manager

## Context

- Requirements, design notes, test plans, and other artefacts stored in `.tmp/`

## Your task

### 1. Gather the inputs

- Start from `.tmp/requirements.md` as the core brief
- Use `.tmp/design.md`, `.tmp/test_design.md`, `.tmp/minutes.md`, or other notes only to supplement the plan when they exist

### 2. Plan the work

- Break the implementation into clear tasks, highlighting ownership, dependencies, and risk areas
- Adjust the depth of planning to match the available artefacts (requirements alone vs full design/test suite)

### 3. Record the breakdown

- Write `.tmp/tasks.md` using the template below so multiple agents can work in parallel

## Notes

Keep the plan actionable but lightweight; call out shared files to avoid conflicts. Do not modify project code while breaking down tasks; keep changes within `.tmp/tasks.md` or related planning artefacts.

---

# Example: .tmp/tasks.md Template

Below is the structure to create in `.tmp/tasks.md`:

```markdown
# Task Breakdown - [Task Name]

## Overview
- Total agents: [1-3 depending on complexity]
- Phases: [number]

## Agent Assignment Strategy
- **Agent 1**: [Frontend/Backend/Full-stack] - maintains ownership of their components across all phases
- **Agent 2**: [Backend/Testing/Config] - maintains ownership of their components across all phases
- **Agent 3**: [Testing/Documentation/Integration] - joins as needed, maintains consistency
- **Continuity**: Each agent maintains context and ownership of their work throughout the project
- **Conflict zones**: [files/areas requiring single-agent ownership to prevent merge conflicts]

## All Tasks Summary

### Phase 1: Foundation
**Goal**: [Core implementation without dependencies]
- [ ] [Task 1] - `[file-path]` (Agent 1)
- [ ] [Task 2] - `[file-path]` (Agent 1)
- [ ] [Task 3] - `[file-path]` (Agent 2)
- [ ] [Task 4] - `[file-path]` (Agent 2)
- [ ] [Task 5] - `[file-path]` (Agent 3)

### Phase 2: Integration
**Goal**: [Connect components and test interactions]
- [ ] [Integration task 1] (Agent 1)
- [ ] [Integration task 2] (Agent 2)

### Phase 3: Testing & Polish
**Goal**: [Comprehensive testing and documentation]
- [ ] [Frontend tests] (Agent 1)
- [ ] [Backend tests] (Agent 2)
- [ ] [Integration tests] (Agent 3)
- [ ] [Documentation updates] (Agent 3)

## Conflict Prevention
- **Shared files**: [list files requiring coordination]
- **Dependencies**: [which tasks must complete before others]
- **Communication points**: [when agents should sync]

## Instructions for Agents

Read the following context to understand the project:
- `.tmp/requirements.md` for the definitive brief
- Any supplemental design, test, or note artefacts currently stored in `.tmp/`
- This task breakdown file (`.tmp/tasks.md`)

**General Instructions**:
- Work only on your assigned tasks in each phase
- Avoid conflicts with shared files listed in Conflict Prevention section
- Update this file to change [ ] to ✅ for completed tasks
- Follow existing code patterns and project conventions
- Coordinate with other agents at phase boundaries

## Agent Prompts by Phase

### Phase 1: Foundation
- **Agent 1**: "Read `.tmp/tasks.md` and complete all tasks assigned to Agent 1 in Phase 1. Work only on your assigned files and avoid shared components until Phase 2."
- **Agent 2**: "Read `.tmp/tasks.md` and complete all tasks assigned to Agent 2 in Phase 1. Work only on your assigned files and avoid shared components until Phase 2."
- **Agent 3**: "Read `.tmp/tasks.md` and complete all tasks assigned to Agent 3 in Phase 1. Work only on your assigned files and avoid shared components until Phase 2."

### Phase 2: Integration
- **Agent 1**: "Proceed to Phase 2 tasks. Integrate your components with other agents' work."
- **Agent 2**: "Proceed to Phase 2 tasks. Integrate your components with other agents' work."

### Phase 3: Testing & Polish
- **Agent 1**: "Proceed to Phase 3 tasks. Add comprehensive testing and final polish."
- **Agent 2**: "Proceed to Phase 3 tasks. Add comprehensive testing and final polish."
- **Agent 3**: "Proceed to Phase 3 tasks. Handle integration testing, documentation, and project coordination."
```
