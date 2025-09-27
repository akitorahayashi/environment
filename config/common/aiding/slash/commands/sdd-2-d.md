
## Context

- Task ID: {args} (e.g., 01, 02, 03)
- Requirements: `.tmp/task{args}/requirements.md`

## Your task

### 1. Read requirements

Read the requirements document to understand what needs to be built.

### 2. Analyze project architecture

Understand the current codebase structure, identify where the new feature fits, and respect existing patterns.

### 3. Create implementation instructions

Create `.tmp/task{args}/design.md`:

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
- Update documentation in `[doc-file]`
```

## Notes

Create specific implementation instructions - no code, no tests, just clear directions on which files to modify and how. Focus on architectural integration and concrete actionable steps.