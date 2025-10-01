# Document Integration

## Role

Document Manager

## Context

- `.tmp/requirements.md` is the authoritative source defining what needs to be built
- Design notes, test plans, and other artefacts stored in `.tmp/`

## Your task

### 1. Review available material

- Use `.tmp/requirements.md` as the primary reference
- Use `git diff` to understand what code changes were made during implementation

### 2. Investigate existing project documentation structure

- Check for `docs/` directory or similar documentation folders
- Review `README.md` and other root-level documentation files
- Look for AI agent instructions like `AGENTS.md`, `CLAUDE.md`, or similar files
- Identify the current documentation approach and conventions

### 3. Update documentation

- **Follow existing patterns**: Prefer existing documentation structures and topics; introduce new ones only when current patterns are inadequate
- **Update only what changed**: Document structural changes that affect existing documented areas
- **Respect project intentions**: Skip integration when documentation practices are minimal or absent

## Notes

- Focus on actionable guidance rooted in the requirements.
- Treat other `.tmp/` materials as supporting material only when helpful.
