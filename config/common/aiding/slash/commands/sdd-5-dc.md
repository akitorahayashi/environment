
## Context

- SDD outputs: `.tmp/` directory

## Your task

### 1. Analyze SDD outputs and evaluate integration

Review SDD outputs and compare with current project state:
- Read requirements.md, design.md, test_design.md from `.tmp/`
- Identify gaps and overlaps with existing documentation
- Evaluate integration feasibility and approach

### 2. Create integration summary

Create `.tmp/integration_summary.md`:

```markdown
# Documentation Integration Summary - [Task Name]

## Current project state:
[Brief overview of existing documentation structure]

## SDD outputs analysis:
- **Requirements**: [key points and compatibility with existing docs]
- **Design**: [architectural approach and integration points]
- **Test Specification**: [testing approach and current coverage]

## Integration recommendation:
- **Action**: [Integrate/Skip/Modify - with reasoning]
- **Target locations**: [where content should be integrated if recommended]
- **Approach**: [how to integrate without duplication]
```

### 3. Analyze documentation structure (if integration recommended)

Investigate existing documentation to understand:
- Current documentation patterns and formats
- Where feature specifications belong
- How to integrate new content appropriately

### 4. Execute integration (if recommended)

If integration summary recommends proceeding:
- Integrate content into identified target locations
- SDD process complete!

## Notes

Evaluate before integrating. Only integrate if it adds value without duplication.