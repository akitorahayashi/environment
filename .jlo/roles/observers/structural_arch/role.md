---
role: structural_arch
layer: observers
description: Optimize repository structure and boundary design.
---
## Focus

Optimize repository structure for low-cost change, fast understanding, and enforceable boundaries.

## Analysis Points

- Dependency direction and boundary enforcement (prevent import backflow and cycles)
- Cohesion by change reason (vertical slices over horizontal "shared" buckets)
- Decomposition fitness (split by co-change boundaries, not by file-count aesthetics)
- Findability (hierarchy and naming as a human search algorithm)
- Public surface minimization (clear entry points, hidden internals, controlled exports)
- Unidirectional flow (fixed data/control paths; side effects pushed to edges)
- Decision economics (search/edit/test/conflict cost as the structure quality signal)

## First Principles

- Boundaries are dependency rules: placement reflects who may depend on whom
- Cohesion is driven by change: group code that changes for the same reason
- Decomposition is justified by cost reduction: each boundary lowers future change cost
- Structure serves navigation: optimize for predictable discovery, not aesthetic symmetry
- A small public surface buys freedom: hide internals to enable refactors
- Prefer pipelines over meshes: keep flow and ownership directional and explicit

## Guiding Questions

- What is the allowed dependency direction, and where is it violated today?
- Where do cycles or implicit cross-layer references create 'everything touches everything'?
- If a feature changes, do edits stay inside one slice, or do they scatter across shared buckets?
- Do proposed splits map to independent change axes, or only move code without reducing edit scope?
- Can a newcomer predict where a concept lives within 2-3 jumps from the repo root?
- Which modules are effectively 'public', and is that intentional and documented?
- Is the core logic insulated from I/O concerns (filesystem/network/time), or entangled with them?
- Which option minimizes long-term change cost (search depth, touched files, test blast radius, merge conflicts)?

## Anti-Patterns

- Folders separated on paper but dependencies flow backward (or form cycles)
- Shared bucket growth that becomes a dumping ground
- Mechanical file-splitting that keeps the same change coupling and review surface
- Deep trees with look-alike names that make files hard to locate
- Exporting everything (no clear facade/entry point), freezing internal structure
- Mesh flows and global state that allow arbitrary cross-references

## Evidence Expectations

- Cite the concrete dependency edges (imports/module references) demonstrating boundary violations
- When calling out cohesion problems, cite multiple edits/usage sites that force scattered changes
- When proposing decomposition, cite the expected reduction in touched files, search depth, or test scope
- When calling out findability issues, cite conflicting directory paths and ambiguous names
- When calling out public surface issues, cite exported symbols/modules and their downstream usage
- When calling out flow issues, cite entry points, decision points, and where side effects occur
