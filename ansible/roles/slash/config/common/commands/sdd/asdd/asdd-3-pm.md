# Generate Prompts

## Role

Prompt Engineer

## Your task

### 1. Draft activation messaging

- Focus on the **All Tasks Summary** section in `.tmp/sdd/tasks.md` to capture every phase/agent assignment

- Turn each checkbox entry into a direct instruction that references `.tmp/sdd/tasks.md`
- Keep agent numbering and phase order identical to the task list
- Carry over any coordination or conflict notes mentioned alongside the tasks

### 2. Record the prompts

- Write `.tmp/sdd/prompts.md` using the template below so every checkbox has a matching activation line
- Keep each prompt short, actionable, and pointing back to `.tmp/sdd/tasks.md`

## Notes

- Do not edit `.tmp/sdd/tasks.md` or any other artefact—your sole deliverable is `.tmp/sdd/prompts.md`
- When a phase assigns multiple checklist items to the same agent, consolidate them into a single prompt line for that agent within that phase

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built
- `.tmp/sdd/design.md` - Implementation design (if exists)
- `.tmp/sdd/tasks.md` - Task breakdown

---

```markdown
# Activation Prompts - [Task Name]

## Guidance
- Prompts must stay in sync with `.tmp/sdd/tasks.md` (especially All Tasks Summary)
- Coordinate at phase boundaries exactly as the plan requires
- Update this file whenever the task list changes

## Prompts by Phase

### Phase 1
- **Agent 1**: "You are agent1. Execute Phase 1 tasks assigned to Agent 1 in `.tmp/sdd/tasks.md`."
- **Agent 2**: "You are agent2. Execute Phase 1 tasks assigned to Agent 2 in `.tmp/sdd/tasks.md`."
- **Agent 3**: "You are agent3. Execute Phase 1 tasks assigned to Agent 3 in `.tmp/sdd/tasks.md`."
- **Agent 4**: "You are agent4. Execute Phase 1 tasks assigned to Agent 4 in `.tmp/sdd/tasks.md`."
- **Reviewer**: "Phase 1 agent work complete. Review merged changes, resolve conflicts, verify build and tests pass."

### Phase 2
- **Agent 1**: "Phase 1 integration is complete. Execute your Phase 2 tasks for Agent 1 in `.tmp/sdd/tasks.md`."
- **Agent 2**: "Phase 1 integration is complete. Execute your Phase 2 tasks for Agent 2 in `.tmp/sdd/tasks.md`."
- **Reviewer**: "Phase 2 agent work complete. Review merged changes, resolve conflicts, verify build and tests pass."

### Phase 3
- **Agent 1**: "Phase 2 integration is complete. Execute your Phase 3 tasks for Agent 1 in `.tmp/sdd/tasks.md`, closing out testing and documentation."
- **Agent 2**: "Phase 2 integration is complete. Execute your Phase 3 tasks for Agent 2 in `.tmp/sdd/tasks.md`, completing launch readiness and comms."
- **Agent 3**: "Phase 2 integration is complete. Execute your Phase 3 tasks for Agent 3 in `.tmp/sdd/tasks.md`."
- **Reviewer**: "Phase 3 agent work complete. Review merged changes, resolve conflicts, verify build and tests pass."
```

Replicate the structure above for any additional phases, ensuring each prompt references the correct agent and phase number. Add a Reviewer prompt after each phase for human orchestration. 