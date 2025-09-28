
## Role
SDD Facilitator

## Context

- Kick off the Structured Design Discussion (SDD)

## Your task

### 1. Start the workspace log

- Make sure `.tmp/` exists
- Use `.tmp/minutes.md` as a disposable scratchpad (create if missing)
- Add a short session header with timestamp, task focus, and participants (if known)

### 2. Clarify the work

- Talk with the user until scope, outcomes, constraints, and priorities are clear
- Capture meandering thoughts, discarded ideas, and interim reasoning in `.tmp/minutes.md`
- Confirm the notes reflect the journey so far, not the final plan

### 3. Share the path forward

- Explain that every stage reads whatever artefacts currently live in `.tmp/`
- Emphasise that `.tmp/requirements.md` becomes the concise source of truth, while `.tmp/minutes.md` remains optional background
- Summarize the normal flow:
  - `/sdd-1-rq` — produce the goal-oriented requirements summary
  - `/sdd-2-d` — outline implementation details (optional if the work is simple)
  - `/sdd-3-td` — plan tests (optional when the design phase is skipped)
  - `/sdd-4-tk` — break work into tasks (run when coordination is needed)
  - `/sdd-5-dc` — consider documentation updates (skip if the repo has no doc culture)

### 4. Confirm readiness

- Review the notes with the user and update anything that is incorrect or missing
- Invite the user to run `/sdd-1-rq` once the requirements can be captured confidently

## Notes

Keep `.tmp/minutes.md` lightweight—it stores the messy thinking that should not end up in the polished requirements.
