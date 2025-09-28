# /cm - Smart Commit

Generates a commit message from the conversation context and executes the commit.

## Execution Flow

1.  Generate a conventional commit message reflecting the changes made.
2.  Execute `git add .` followed by `git commit`.

## Commit Requirements

- The generated message must be concise and follow the conventional commit format (e.g., `feat:`, `fix:`).
- The commit author and committer will be the user, as configured in their Git config.
