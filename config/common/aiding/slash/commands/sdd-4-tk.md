
## Role
Engineering Manager

## Context

- Requirements, design notes, test plans, and other artefacts stored in `.tmp/`

## Your task

Create `.tmp/tasks.think.md` and log your reasoning as you progress. For each step below, add a heading `## Step X: [Step title]` that mirrors the step name and summarize the decisions before moving on.

### 1. Gather the inputs

- Start from `.tmp/requirements.md` as the core brief
- Use `.tmp/design.md`, `.tmp/test_design.md`, `.tmp/minutes.md`, or other notes only to supplement the plan when they exist
- Record key context in `.tmp/tasks.think.md` under `## Step 1: Gather the inputs` before progressing.

### 2. Map conflicts before planning

- Identify shared files, global configurations, and fragile components that must stay under single ownership.
- Capture dependencies and handoff risks upfront so later phase and agent choices respect these constraints.
- Summarize conflict risks in `.tmp/tasks.think.md` under `## Step 2: Map conflicts before planning`.

### 3. Design phases and agent usage

- Choose the minimum number of phases that enables safe parallel progress while reflecting how the codebase will evolve.
- Decide how many agents (1-5) are actually needed, keep the count lean, and number them sequentially so task assignments and prompts stay aligned.
- Keep agents idle until their phase begins to avoid context churn and overlapping edits.
- Never split conflict-prone work across multiple agents or phases.
- Document chosen phases, agent assignments, and rationale in `.tmp/tasks.think.md` under `## Step 3: Design phases and agent usage`.

### 4. Build `.tmp/tasks.md`

- Review the notes captured in `.tmp/tasks.think.md`.
- When the thinking log feels solid, open `.tmp/tasks.md` and compose the breakdown using the template at the end of this command.
- Base each section on the decisions recorded in `.tmp/tasks.think.md` so ownership, sequencing, and risks stay aligned.
- Highlight opportunities for safe concurrency only after the conflict boundaries are fixed.
- Update the Conflict Prevention guidance whenever task assignments or sequencing change.

## Notes

Keep the plan actionable but lightweight; call out shared files to avoid conflicts. Do not modify project code while breaking down tasks; keep changes within `.tmp/tasks.md` or related planning artefacts.

# Example: .tmp/tasks.md Template

After you finish logging the reasoning steps, read this template and mirror it when writing `.tmp/tasks.md`. Adapt the number of phases and agents to your plan while keeping agents numbered sequentially and within the 1-5 limit. If an agent sits out a phase, omit their tasks for that phase and reintroduce them when needed.

```markdown
# Task Breakdown - [Task Name]

## Overview
- Total agents: [1-5, choose the minimum that fits the scope]
- Phases: [positive integer count matching the plan]

## Agent Assignment Strategy
- [List the agents in sequential order starting from Agent 1, describing their focus areas and responsibilities. Include only the agents you plan to activate for this effort.]
- **Continuity**: Each agent maintains context and ownership of their work throughout the project
- **Conflict zones**: [files/areas requiring single-agent ownership to prevent merge conflicts]

## All Tasks Summary

Adjust the phase names, goals, and task counts to match your plan while keeping agents aligned with their ownership.

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


## Instructions for Agents

Read the following context to understand the project:
- `.tmp/requirements.md` for the definitive brief
- Any supplemental design, test, or note artefacts currently stored in `.tmp/`
- This task breakdown file (`.tmp/tasks.md`)

**General Instructions**:
- Work only on your assigned tasks in each phase
- Avoid conflicts with shared files listed in the Conflict Prevention section
- Update this file to change [ ] to ✅ for completed tasks
- Follow existing code patterns and project conventions
- Coordinate with other agents at phase boundaries

## Agent Activation Prompts

### Phase 1
- **Agent 1**: "youare agent1, at .tmp/tasks.md. Work according to Phase 1 tasks assigned to Agent 1. Respect the Conflict Prevention guidance and keep ownership of your files."
- **Agent 2**: "youare agent2, at .tmp/tasks.md. Work according to Phase 1 tasks assigned to Agent 2. Respect the Conflict Prevention guidance and keep ownership of your files."

### Phase 2
- **Agent 1**: "Once Phase 1 is complete, return to .tmp/tasks.md and execute your Phase 2 tasks for Agent 1. Coordinate handoffs defined in the Conflict Prevention section before editing shared artefacts."
- **Agent 3**: "Once Phase 1 is complete, return to .tmp/tasks.md and execute your Phase 2 tasks for Agent 3. Coordinate handoffs defined in the Conflict Prevention section before editing shared artefacts."

### Phase 3
- **Agent 1**: "Once Phase 2 is complete, return to .tmp/tasks.md and execute your Phase 3 tasks for Agent 1, closing out testing and documentation without reassigning conflict-sensitive files."
- **Agent 2**: "Once Phase 2 is complete, return to .tmp/tasks.md and execute your Phase 3 tasks for Agent 2, completing launch readiness and comms while respecting Conflict Prevention notes."

Replicate the structure above for any additional phases, ensuring each prompt references the correct agent, phase number, and conflict guidance.
```
