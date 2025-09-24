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
- **Arguments**: Passed as `{args}` placeholder in command templates
  - Arguments appear at end of command prompt as `ARGUMENTS: <user-input>`
  - Template placeholders like `{args}` are replaced with actual user input
  - Example: `/tst can you see this` → `{args}` becomes `can you see this`

## Gemini CLI (.toml format)
- **Description**: Human-readable description
- **Prompt**: Instructions for AI
- **Argument Passing**: `{{args}}` placeholder
  - Raw replacement: Used directly in text
- **Usage Example**: `/cmd arg1 arg2` → args = "arg1 arg2"

## Common Patterns
1. Header Section: Human-readable information (title, description, etc.)
2. Body Section: Detailed instructions for AI
3. Argument Handling:
   - Claude: `{args}` placeholder replacement + `ARGUMENTS:` system message
   - Gemini: `{{args}}` placeholder replacement only

## Generation Process (Claude)
The `config/common/slash/claude.sh` script:
1. Reads `config.json` for command definitions
2. Generates `.md` files in `~/.claude/commands/`
3. Includes `argument-hint` in frontmatter if specified
4. Embeds prompt content from referenced template files
5. Runtime: Claude Code substitutes `{args}` and appends `ARGUMENTS:` line