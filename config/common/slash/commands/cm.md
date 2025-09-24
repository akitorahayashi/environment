# /cm - Smart Commit

Generates a commit message from the conversation context and executes the commit. This command relies on editing history only, not `git diff` or `git status`.

## Execution Flow

1.  Generate a conventional commit message reflecting the changes made.
2.  Append a `Co-authored-by:` trailer for the responding Large Language Model (e.g., Gemini).
3.  Execute `git add .` followed by `git commit`.

## Commit Requirements

- The generated message must be concise and follow the conventional commit format (e.g., `feat:`, `fix:`).
- The commit author and committer will be the user, as configured in their Git settings.
- The commit must include a `Co-authored-by:` trailer for the LLM.