# Slash Command Argument Patterns

## Claude Code (.md format)
- **Front Matter**: YAML for human-readable information
  ```yaml
  ---
  title: "Command Name"
  argument-hint: "Argument Description"
  ---
  ```
- **Body**: Instructions for AI, with Markdown headers
  ```markdown
  # /cmd - Command Name
  
  Instruction content...
  ```
- **Arguments**: Passed as selected lines via system reminder

## Gemini CLI (.toml format)  
- **Description**: Human-readable description
- **Prompt**: Instructions for AI
- **Argument Passing**: `{{args}}` placeholder
  - Raw replacement: Used directly in text
- **Usage Example**: `/cmd arg1 arg2` → args = "arg1 arg2"

## Common Patterns
1. Header Section: Human-readable information (title, description, etc.)
2. Body Section: Detailed instructions for AI
3. Argument Handling: Claude uses selected lines, Gemini uses placeholders