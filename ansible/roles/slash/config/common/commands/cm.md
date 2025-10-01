# /cm - Smart Commit

Generates a commit message from the conversation context and executes the commit.

## Execution Flow

1.  Generate a conventional commit message reflecting the changes made.
2.  Preflight:
    - Show `git status --porcelain` and abort if clean (no changes).
    - Exclude large/binary/artifact paths (e.g., `dist/`, `node_modules/`, `*.lock` unless intended).
3.  Execute `git add -A` (respecting excludes) and `git commit --no-verify` (or configurable).
4.  Output the commit SHA and subject.

## Commit Requirements

- The generated message must be concise and follow the conventional commit format (e.g., `feat:`, `fix:`).
- The commit author and committer will be the user, as configured in their Git config.
