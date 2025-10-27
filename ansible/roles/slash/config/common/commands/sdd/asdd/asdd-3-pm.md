# Generate Prompts

## Role

Prompt Engineer

## Your task

### 1. Read phase files

- Read all `.tmp/sdd/tasks/phase_*.md` and `.tmp/sdd/tasks/overview.md`
- Extract agent roles and task assignments from each phase

### 2. Generate prompts

- Create one prompt per agent per phase in `.tmp/sdd/prompts.md`
- Include role description from task files
- Generate simplified prompts for sub-agents
- Add final review phase prompt (new LLM reviews codebase critically)

## Notes

- Do not edit task files—your sole deliverable is `.tmp/sdd/prompts.md`
- Keep prompts short and actionable

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built
- `.tmp/sdd/design.md` - Implementation design (if exists)
- `.tmp/sdd/tasks/` - Phase task files

---

```markdown
# Activation Prompts - [Task Name]

## Guidance
- Prompts must stay in sync with phase task files in `.tmp/sdd/tasks/`
- Update this file whenever task files change

## Prompts by Phase

### Phase 1: [Name]
- **Agent 1 (Backend API)**: "Execute Phase 1 tasks in `.tmp/sdd/tasks/phase_1.md` for Agent 1."
- **Agent 2 (Frontend)**: "Execute Phase 1 tasks in `.tmp/sdd/tasks/phase_1.md` for Agent 2."
- **Sub-Agent 1 (Import cleanup)**: "Execute Phase 1 tasks in `.tmp/sdd/tasks/phase_1.md` for Sub-Agent 1."

### Phase 2: [Name]
- **Agent 1 (Integration)**: "Execute Phase 2 tasks in `.tmp/sdd/tasks/phase_2.md` for Agent 1."

### Phase N: Quality & Review
- **Sub-Agent (Linter/Formatter)**: "Run linter and formatter on all changed files in `.tmp/sdd/tasks/phase_N.md`."
- **Reviewer**: "Read `.tmp/sdd/requirements.md`, `.tmp/sdd/design.md`, and all phase task files. Review codebase state critically against requirements. Edit code if permitted to fix issues, otherwise report findings."
``` 