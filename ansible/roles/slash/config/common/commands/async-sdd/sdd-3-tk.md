# Break Down Tasks

## Role

Engineering Manager

## Context

- `.tmp/requirements.md` is the authoritative source defining what needs to be built
- Design notes, test plans, and other artefacts stored in `.tmp/`

## Your task

### 1. Gather the inputs

- Start from `.tmp/requirements.md` as the core brief
- Use `.tmp/design.md`, `.tmp/test_design.md`, or other notes in `.tmp/` only to supplement the plan when they exist

### 2. Design phases and agent usage

- Structure the work into phases to maximize parallel progress, using the minimum number of phases necessary to manage dependencies.
- Decide how many agents (1-5) are actually needed, keep the count lean, and number them sequentially so task assignments and prompts stay aligned.
- Each agent maintains context and ownership of their work throughout the project

### 3. Build `.tmp/tasks.md`

- Compose the breakdown using the template at the end of this command.
- Maximize opportunities for parallel work - agents can work simultaneously even on shared files.
- Note any critical coordination points between phases if needed.

---

## Task Breakdown Patterns

Apply these patterns when creating `.tmp/tasks.md`:

**Typical Phase Flow**:
1. **Parallel Implementation**: Maximize agents on independent features
2. **Integration**: Fewer agents (1-2) to reduce merge conflicts
3. **Testing**: Mocks → tests → CI updates → test runs → fixes
4. **Quality**: Single agent for linting/formatting
5. **Documentation** (if needed): Update only changed areas, follow existing patterns

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
- Read `.tmp/requirements.md`, `.tmp/design.md`, `.tmp/tasks.md`
- Follow project conventions
- Mark completed tasks with ✅

After implementation (if documentation exists):
- Update docs only where structural changes occurred
- Follow existing documentation patterns

### Phase N: [Name]
**Goal**: [Objective]
- [ ] [Task with file path] (Agent X)
```