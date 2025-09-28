# Slash Command Prompt Behavior

## Claude Code (.md format)
- **Front Matter**: Contains only `title` metadata; dynamic `argument-hint` fields have been retired.
- **Body**: Markdown instructions that must stand alone without `{args}` placeholders.
- **Usage**: Commands execute with the static prompt content exactly as authored in `config/common/aiding/slash/commands/`.

## Gemini CLI (.toml format)
- **Description**: Preserved from `config.json`.
- **Prompt**: Multi-line string copied verbatim from the shared Markdown template; no `{{args}}` substitution occurs.
- **Usage**: Gemini interprets the generated prompt directly, so trailing arguments in slash invocations are ignored.

## Common Rules
1. Shared templates must avoid references to runtime arguments or `{args}`-style placeholders.
2. Generation scripts (`claude.sh`, `gemini.sh`, `codex.sh`) simply mirror the prompt text and metadata; introducing argument support requires explicit design changes.
3. Maintain consistency by validating regenerated command files contain no argument hints after running `just cmn-slash-claude` or `just cmn-slash-gemini`.
