
## Role
Prompt Engineer

## Context

- Task breakdown and supporting artefacts live in `.tmp/`

## Your task

### 1. Gather the plan inputs

- Open `.tmp/tasks.md` and focus on the **All Tasks Summary** section to capture every phase/agent assignment

### 2. Draft activation messaging

- Turn each checkbox entry into a direct instruction that references `.tmp/tasks.md`
- Keep agent numbering and phase order identical to the task list
- Carry over any coordination or conflict notes mentioned alongside the tasks

### 3. Record the prompts

- Write `.tmp/prompts.md` using the template below so every checkbox has a matching activation line
- Keep each prompt short, actionable, and pointing back to `.tmp/tasks.md`

## Notes

Do not edit `.tmp/tasks.md` or any other artefact—your sole deliverable is `.tmp/prompts.md`.

---

```markdown
# Activation Prompts - [Task Name]

## Guidance
- Prompts must stay in sync with `.tmp/tasks.md` (especially All Tasks Summary)
- Coordinate at phase boundaries exactly as the plan requires
- Update this file whenever the task list changes

## Prompts by Phase

### Phase 1
- **Agent 1**: "youare agent1, at .tmp/tasks.md. Work according to Phase 1 tasks assigned to Agent 1."
- **Agent 2**: "youare agent2, at .tmp/tasks.md. Work according to Phase 1 tasks assigned to Agent 2."
- **Agent 3**: "youare agent3, at .tmp/tasks.md. Work according to Phase 1 tasks assigned to Agent 3."
- **Agent 4**: "youare agent4, at .tmp/tasks.md. Work according to Phase 1 tasks assigned to Agent 4."

### Phase 2
- **Agent 1**: "Once Phase 1 is complete, return to .tmp/tasks.md and execute your Phase 2 tasks for Agent 1."
- **Agent 2**: "Once Phase 1 is complete, return to .tmp/tasks.md and execute your Phase 2 tasks for Agent 2."

### Phase 3
- **Agent 1**: "Once Phase 2 is complete, return to .tmp/tasks.md and execute your Phase 3 tasks for Agent 1, closing out testing and documentation."
- **Agent 2**: "Once Phase 2 is complete, return to .tmp/tasks.md and execute your Phase 3 tasks for Agent 2, completing launch readiness and comms."
- **Agent 3**: "Once Phase 2 is complete, return to .tmp/tasks.md and execute your Phase 3 tasks for Agent 3."

Replicate the structure above for any additional phases, ensuring each prompt references the correct agent, phase number, and conflict guidance.
```