# Design Solution

## Role

Software Architect

## Your task

- Describe how the change fits into the existing architecture and respects current patterns
- Point out the files, modules, or services that will be touched and why (including test files—respect project testing culture)
- Identify existing documentation that will need updates (README.md, AGENTS.md, docs/)—follow project documentation culture
- If the task is simple enough that no design is needed, say so and note the reasoning
- Write `.tmp/sdd/design.md` using the template below

## Notes

- Focus on actionable guidance; do not write code
- Do not modify project code while preparing the design; keep outputs confined to `.tmp/sdd/` directory

## Reference

- `.tmp/sdd/requirements.md` - What needs to be built

---

```markdown
# Implementation Instructions - [Task Name]

## Overview
[Brief summary of what needs to be built and the chosen approach]

## Files to Modify/Create/Delete (examples - use only what applies)

### 1. Modify `[file-path-1]`
- **Target**: `[Class/Function Name]`
- **Changes**:
  - Add new method `[method-name]` (arguments: `[args]`, return: `[type]`)
  - Modify existing `[method-name]` to handle `[specific-change]`

### 2. Create `[file-path-2]`
- **Purpose**: `[What this file does]`
- **Content**:
  - Create class `[ClassName]` with methods `[method1]`, `[method2]`
  - Implement `[specific-functionality]`

### 3. Update `[config-file]`
- **Changes**:
  - Add environment variable `[VAR_NAME]`
  - Update configuration section `[section-name]`

### 4. Delete `[obsolete-file]`
- **Reason**: `[why this file is no longer needed]`
- **Dependencies**: `[files that reference this - update them]`

### 5. Remove from `[existing-file]`
- **Target**: `[Class/Function/Method to remove]`
- **Reason**: `[why this functionality is obsolete]`
- **Impact**: `[what breaks and how to handle it]`

### 6. Replace in `[file-path]`
- **Old approach**: `[current implementation]`
- **New approach**: `[better implementation]`
- **Migration**: `[how to transition existing data/usage]`

## Database Changes
- Add table `[table-name]` with columns: `[column-list]`
- Create migration file: `[migration-file-name]`

## Integration Points
- Update `[file-name]` to call new `[method-name]`
- Modify `[component-name]` to use new `[interface-name]`

## Environment Setup
- Add to `.env.example`: `[new-variables]`

## Documentation Updates
- **Files to update**: List existing documentation files (README.md, AGENTS.md, docs/*)
- **Update areas**: Specific sections requiring changes based on this implementation
- **Note**: Only update existing documentation—never create new files or directories
```
