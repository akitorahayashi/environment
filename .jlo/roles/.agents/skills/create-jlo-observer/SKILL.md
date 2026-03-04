---
name: create-jlo-observer
description: Create or review `.jlo/roles/observers/<role>/role.md` with a narrow analytical lens, reusable signal classes, and explicit evidence standards.
---

# Create JLO Observer

## Core Objective

Define an observer `role.md` that produces repeatable analysis quality from repository evidence.

## Output Contract

Target file:
- `.jlo/roles/observers/<role>/role.md`

Required shape:

```yaml
role: <role_id>
description: <string>
layer: observers
profile:
  focus: <string>
  analysis_points: <non-empty sequence>
  first_principles: <non-empty sequence>
  guiding_questions: <non-empty sequence>
  anti_patterns: <non-empty sequence>
  evidence_expectations: <non-empty sequence>
constraint: <sequence>
```

Validator-critical fields:
- `role`
- `description`
- `layer` (must be `observers`)
- `profile.focus`
- `profile.analysis_points`
- `constraint` (sequence, can be empty)

## Design Workflow

1. Set `focus` as one stable analytical boundary.
2. Write `analysis_points` as recurring signal classes, not incident examples.
3. Write `first_principles` as the reason a deviation causes harm. "X implies Y because Z", not "X is important" or a restatement of `analysis_points`.
4. Write `guiding_questions` with a concrete answer type (yes/no, which category, which condition). Open-ended inquiry does not force judgment.
5. Write `evidence_expectations` as minimum proof required before accepting claims.
6. Confirm the role stays analytical and does not prescribe implementation work.

## Boundary Rules

- Do not define the role by one tool, one file, or one temporary incident.
- Do not encode layer-level task procedure into role.md.
- Do not add repository-specific input checklists in role.md.
- Keep wording narrow enough to reject out-of-scope requests.

## Field Design Principles

Each field serves one epistemic function. Fields restating the same topic in different wording add no judgment capacity.

- `analysis_points`: Observable signal classes. What to look for, not why it matters.
- `first_principles`: The reason a deviation causes harm. Resolves judgment calls; does not restate `analysis_points`.
- `guiding_questions`: Questions with a concrete answer type. Not exploratory prompts.
- `anti_patterns`: Role misuse patterns, not a catalog of domain-level bad practices.
- `evidence_expectations`: Minimum proof required per topic covered in `analysis_points`.

Self-containment: terminology and criteria must not depend on external documents. Define concepts inside the role.

Topic balance: if the role covers N topics, each topic appears proportionally across fields. One topic dominating every field is a design error.

Criteria over prohibition: blanket prohibition of a design element produces cognitive bias. Provide the classification criteria by which the element is evaluated instead.

## Anti-Pattern Checks

- `focus` is broad enough to absorb unrelated domains.
- `analysis_points` are action items or refactoring plans.
- `analysis_points` are path-specific checklists instead of reusable signal classes.
- `evidence_expectations` are missing, weak, or unfalsifiable.
- The role duplicates another observer with renamed wording only.
- Fields restate the same topic in different wording without adding judgment capacity.
- Role contains terminology that requires reading an external document to interpret.
- One topic dominates every field while others are underrepresented.
- A field instructs the reader to judge or balance without providing the criteria to do so.

## Review Mode

When reviewing an existing observer role, return only:
1. Schema violations.
2. Scope ambiguity in `focus`.
3. Non-reusable entries in `analysis_points`.
4. Concrete rewrites for `focus`, `analysis_points`, and `evidence_expectations`.
