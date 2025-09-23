# GitHub CLI Alias Design Requirements

## Design Principles

### 1. Alias Classification
#### A. Action Aliases for Users
- `re-cl`: Repo clone
- `pr-cr`: PR creation
- `pr-mr`: PR merge

#### B. Information Retrieval and LLM Integration Aliases
- Purpose: Provide structured output to inform users or LLMs about available data
- Designed for easy LLM comprehension
- Intended for piping to LLMs for analysis and suggestions

### 2. LLM Integration Requirements
- Compatible with piping to `claude -p` or `gemini -p`
- Include context information that LLMs can easily understand
- Consistent output format (section delimiters, clear labels)

### 3. Required New Aliases (Proposal)
- `info-diff`: Branch differences (with LLM context)
- `info-commits`: Commit history (LLM-formatted)
- `info-pr`: Detailed PR information (JSON + diff)
- `info-status`: Comprehensive repository status information
- `llm-pr-suggest`: Data output for PR suggestions
- `llm-commit-suggest`: Data output for commit suggestions

### 4. Standard Output Format
```
=== Section Name ===
Information content
=== Next Section ===
```

### 5. Usage Examples
```bash
# Get PR title and body suggestions from LLM
gh llm-pr-suggest feature-branch | claude -p

# Have LLM review a PR
gh info-pr 123 | claude -p "Review this PR"

# Get commit message suggestions from LLM
gh llm-commit-suggest | gemini -p
```

## Technical Considerations
- Utilize jq for JSON processing
- Integration with git commands
- Error handling
- Performance (e.g., limits)
- Maintain compatibility with existing aliases