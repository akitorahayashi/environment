# Break Down Tasks

## Role

Engineering Manager

## Your task

### 1. Design phases and agent usage

- Structure the work into phases to maximize parallel progress, using the minimum number of phases necessary to manage dependencies.
- Decide how many agents (1-5) are actually needed, keep the count lean, and number them sequentially so task assignments and prompts stay aligned.
- Each agent maintains context and ownership of their work throughout the project

### 2. Build `.tmp/sdd/tasks.md`

- Compose the breakdown using the template below
- Maximize opportunities for parallel work - agents can work simultaneously even on shared files
- Note any critical coordination points between phases if needed

## Notes

- Do not write code during this planning phase—outputs stay in `.tmp/sdd/`

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built
- `.tmp/sdd/design.md` - Implementation design (if exists)

---

## Task Breakdown Patterns

Apply these patterns when creating `.tmp/sdd/tasks.md`:

**Typical Phase Flow**:
1. **Parallel Implementation**: Maximize agents on independent features
2. **Integration**: Fewer agents (1-2) to reduce merge conflicts
3. **Testing**: Mocks → tests → CI updates → test runs → fixes
4. **Quality**: Single agent for linting/formatting
5. **Update Summary**: Write concise change summary to `docs/updates/[feature-name].md`

**Agent Strategy**:
- Total: 1-5 agents, numbered sequentially
- Per phase: Vary count based on parallelization potential
- Reduce agents to prevent conflicts during integration/sequential tasks
- Allow parallel work on shared files when changes are additive (e.g., multiple agents writing independent test fixtures to shared config)

**Task Format**: `- [ ] [Action on specific/path/file.ext] (Agent N)`

**Template**:
```markdown
# Task Breakdown - [Name]

## Overview
- Total agents: [1-5]
- Phases: [count]

## All Tasks Summary

Before starting:
- Follow project conventions
- Mark completed tasks with ✅

After implementation:
- Write concise change summary to `docs/updates/[feature-name].md`

**Note**: `docs/` files are reference only—do not update unless explicitly requested by user.

### Phase N: [Name]
**Goal**: [Objective]
- [ ] [Task with file path] (Agent X)
```