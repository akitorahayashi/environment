# Task Breakdown - MCP Configuration Synchronization

## Overview
- Total agents: 3
- Phases: 3

## Agent Assignment Strategy
- **Agent 1**: Configuration Automation (Ansible) – owns role/task updates
- **Agent 2**: Build & Tooling – owns workflow orchestration (justfile) and collection dependencies
- **Agent 3**: Documentation & Validation – owns docs, verification guidance, and optional validation hooks
- **Continuity**: Each agent maintains ownership of their scope across all phases
- **Conflict zones**: `ansible/roles/mcp/tasks/main.yml`, `config/common/aiding/codex/config.toml` (write via automation only), `.tmp/requirements.md`

## All Tasks Summary

### Phase 1: Foundation
**Goal**: Establish core synchronization logic and prerequisites
- [ ] Extend MCP role to conditionally read and update Codex config – `ansible/roles/mcp/tasks/main.yml` (Agent 1)
- [ ] Ensure role dependency on `community.general` is declared – `ansible/roles/mcp/meta/main.yml` (Agent 2)
- [ ] Draft process note clarifying Codex-before-MCP sequencing – `.tmp/notes_ops.md` or existing ops doc (Agent 3)

### Phase 2: Integration
**Goal**: Connect workflow and ensure deterministic execution order
- [ ] Add combined recipe or ordering guidance to automation entrypoint – `justfile` (Agent 2)
- [ ] Verify updated MCP task writes synchronized TOML without disturbing other settings (review/analysis) – (Agent 3)

### Phase 3: Testing & Polish
**Goal**: Validate end-to-end flow and finalize documentation
- [ ] Run dry-run or check-mode execution to confirm idempotent behavior and conditional skip paths – (Agent 1)
- [ ] Document troubleshooting/extension steps for MCP catalogue updates – `docs/` or `.tmp/notes_ops.md` (Agent 3)
- [ ] Optional verification script or checklist ensuring repo/user configs match authoritative list – `.tmp/validation.md` (Agent 3)

## Conflict Prevention
- **Shared files**: `ansible/roles/mcp/tasks/main.yml`, `justfile`, documentation targets – coordinate commits to avoid overlaps
- **Dependencies**: Agent 1’s task relies on Agent 2 supplying `community.general`; Agent 2’s justfile changes should follow Agent 1’s task structure to reference new behavior; Agent 3’s verification depends on Phase 1 implementation
- **Communication points**: Sync after Phase 1 for readiness to integrate; quick stand-up before Phase 3 to align on validation steps

## Instructions for Agents

Read the following context to understand the project:
- `.tmp/requirements.md` for the definitive brief
- `.tmp/design.md` and `.tmp/minutes.md` for supporting details
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

