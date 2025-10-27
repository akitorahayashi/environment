# Break Down Tasks

## Role

Engineering Manager

## Your task

### 1. Design phases and agent usage

- Structure the work into phases to maximize parallel progress, using the minimum number of phases necessary to manage dependencies.
- Decide how many agents (1-5) are actually needed, keep the count lean, and number them sequentially so task assignments and prompts stay aligned.
- Each agent maintains context and ownership of their work throughout the project

### 2. Build `.tmp/sdd/tasks/phase_N.md` files

- Create one file per phase (e.g., `phase_1.md`, `phase_2.md`)
- Tag each agent with brief role description (e.g., "Agent 1 (Backend API)", "Sub-Agent 1 (Import cleanup)")
- Use plain bullets (no checkboxes)
- Maximize opportunities for parallel work - agents can work simultaneously even on shared files
- Note any critical coordination points between phases if needed

## Notes

- Do not write code during this planning phase—outputs stay in `.tmp/sdd/`

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built
- `.tmp/sdd/design.md` - Implementation design (if exists)

---

## Task Breakdown Patterns

Apply these patterns when creating phase files:

**Typical Phase Flow**:
1. **Parallel Implementation**: Maximize agents on independent features
2. **Integration**: Fewer agents (1-2) to reduce merge conflicts
3. **Testing**: Mocks → tests → CI updates → test runs → fixes
4. **Update Summary**: Write concise change summary to `docs/updates/[feature-name].md`

**Fixed Final Phase** (always include):
- **Phase N: Quality & Review**: Sub-Agent runs linter/formatter, then Reviewer LLM reviews codebase critically against requirements and edits if permitted

**Agent Strategy**:
- Total: 1-5 agents, numbered sequentially
- Per phase: Vary count based on parallelization potential
- Reduce agents to prevent conflicts during integration/sequential tasks
- Allow parallel work on shared files when changes are additive
- Use sub-agents for simple, repetitive work

**Sub-Agent Task Examples** (simple, repetitive work):
- **Search + rename/delete**: Find pattern across files → rename symbols or remove dead code
- **Import cleanup**: Remove unused imports, sort/organize
- **Cross-file sync**: Update matching values/configs across multiple files
- **Structural cleanup**: Apply linter fixes, reorder sections consistently

**Task Format**: `- [Action on specific/path/file.ext] (Agent N: Role)` or `(Sub-Agent N: Task type)`

**Phase File Template** (`.tmp/sdd/tasks/phase_N.md`):
```markdown
# Phase N: [Name]

**Goal**: [Objective]

**Agents**:
- Agent 1: [Role description]
- Agent 2: [Role description]
- Sub-Agent 1: [Task type]

**Tasks**:
- [Action on specific/path/file.ext] (Agent 1: Role)
- [Action on specific/path/file.ext] (Agent 2: Role)
- [Action on specific/path/file.ext] (Sub-Agent 1: Task type)

**Coordination**: [Critical dependencies or sync points, if any]
```

**Project Overview File** (`.tmp/sdd/tasks/overview.md`):
```markdown
# Task Breakdown Overview - [Name]

## Summary
- Total agents: [1-5]
- Total phases: [count]

## Phase Sequence
1. Phase 1: [Name] - [Brief goal]
2. Phase 2: [Name] - [Brief goal]
...
N. Phase N: Quality & Review - Linting/formatting + critical codebase review

## Notes
- Follow project conventions
- Write concise change summary to `docs/updates/[feature-name].md` after implementation
- `docs/` files are reference only—do not update unless explicitly requested by user
```