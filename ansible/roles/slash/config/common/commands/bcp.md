# /bcp - Branch Commit Push

## Review Changes First

- List changed files: `git status -s`
- Review diffs for key files: `git diff -- path/one path/two`

## Branch, Commit, Push

1. Pick a branch name (e.g. `feat/user-auth`).
2. Create and switch: `git checkout -b <branch-name>`.
3. Stage and commit: `git add -A && git commit -m "<message>"`.
4. Push: `git push -u origin <branch-name>`.
