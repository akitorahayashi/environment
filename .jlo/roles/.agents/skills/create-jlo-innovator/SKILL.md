---
name: create-jlo-innovator
description: Create or review `.jlo/roles/innovators/<role>/role.md` with a strategic intervention lens, explicit evidence standards, and a clear proposal quality bar.
---

# Create JLO Innovator

## Core Objective

Define an innovator `role.md` that generates high-leverage intervention proposals from repository reality.

## Output Contract

Target file:
- `.jlo/roles/innovators/<role>/role.md`

Required shape:

```yaml
role: <role_id>
description: <string>
layer: innovators
profile:
  focus: <string>
  analysis_points: <non-empty sequence>
  first_principles: <non-empty sequence>
  guiding_questions: <non-empty sequence>
  anti_patterns: <non-empty sequence>
  evidence_expectations: <non-empty sequence>
  proposal_quality_bar: <non-empty sequence>
constraint: <sequence>
```

Validator-critical fields:
- `role`
- `description`
- `layer` (must be `innovators`)
- `profile.focus`
- `profile.analysis_points`
- `profile.proposal_quality_bar`
- `constraint` (sequence, can be empty)

## Design Workflow

1. Set `focus` as one stable intervention boundary.
2. Write `analysis_points` as recurring leverage classes, not patch-level fix categories.
3. Write `first_principles` as the reason the mechanism approach is justified over a local fix. "X implies Y because Z", not "X is important" or a restatement of `analysis_points`.
4. Write `guiding_questions` with a concrete answer type (yes/no, which condition, which scope). Open-ended inquiry does not force judgment.
5. Write `evidence_expectations` as minimum proof required before accepting strategic claims.
6. Write `proposal_quality_bar` as explicit publish/no-publish criteria.
7. Confirm strict separation from observer duties.

## Boundary Rules

- Do not collapse into observer work (quality auditing, issue triage, patch diagnosis).
- Do not define the role by one tool, one file, or one temporary incident.
- Do not encode layer-level task procedure into role.md.
- Keep wording narrow enough to reject low-leverage proposal classes.

## Field Design Principles

Each field serves one epistemic function. Fields restating the same topic in different wording add no judgment capacity.

- `analysis_points`: Intervention classes with systemic reach. What type of mechanism to introduce, not why it matters.
- `first_principles`: The reason the mechanism approach outperforms a local fix. Resolves judgment calls; does not restate `analysis_points`.
- `guiding_questions`: Questions with a concrete answer type. Not exploratory prompts.
- `anti_patterns`: Role misuse patterns, including proposing local patches instead of mechanisms.
- `evidence_expectations`: Minimum proof required per topic covered in `analysis_points`.
- `proposal_quality_bar`: Explicit reject conditions, not only pass conditions. "Reject if not X" is more actionable than "Publish if X".

Self-containment: terminology and criteria must not depend on external documents. Define concepts inside the role.

Topic balance: if the role covers N topics, each topic appears proportionally across fields. One topic dominating every field is a design error.

Criteria over prohibition: blanket prohibition of a design element produces cognitive bias. Provide the classification criteria by which the element is evaluated instead.

## Anti-Pattern Checks

- `focus` is broad enough to absorb unrelated domains.
- `analysis_points` are local refactoring categories with no mechanism shift.
- The role is defined by one tool preference instead of intervention outcome class.
- `evidence_expectations` are weak, missing, or unfalsifiable.
- `proposal_quality_bar` cannot reject low-quality proposals.
- Fields restate the same topic in different wording without adding judgment capacity.
- Role contains terminology that requires reading an external document to interpret.
- One topic dominates every field while others are underrepresented.
- A field instructs the reader to judge or balance without providing the criteria to do so.

## Review Mode

When reviewing an existing innovator role, return only:
1. Schema violations.
2. Observer-duty overlap.
3. Weak abstraction in `analysis_points`.
4. Concrete rewrites for `focus`, `analysis_points`, and `proposal_quality_bar`.
