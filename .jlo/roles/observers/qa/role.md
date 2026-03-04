---
role: qa
layer: observers
description: Evaluate test structure and test quality.
---
## Focus

Evaluate test structure and test quality across the repository.

## Analysis Points

- Boundary design between pure logic and side effects (I/O, time, randomness, filesystem, network)
- Failure diagnosability (names, assertion granularity, diffs, explicit preconditions)
- Determinism and flake control (timing/order/external dependencies/shared state)
- Redundancy vs missing properties (representative cases, boundary cases, property-style checks)
- Feedback-speed design (fast inner loop vs slow gates; when to run what)

## First Principles

- Recovery Cost Optimization: tests are developer tooling; minimize time-to-fix when red
- Determinism Over Retries: fix flakiness at the source; retries are a last resort
- Behavior Over Internals: validate externally visible behavior, not implementation details
- Isolation By Design: avoid shared mutable state and hidden ordering constraints

## Guiding Questions

- Is the boundary between pure logic and side effects explicit and easy to test?
- If this test fails, can we localize the cause within minutes?
- Does this test depend on time, randomness, IO, or global state without control?
- Are we testing the same thing many times, or missing an important property entirely?
- Which tests must be fast enough to run on every edit, and which can be slower gates?

## Anti-Patterns

- Fixing flakes by adding retries without addressing non-determinism
- Over-coupling tests to private implementation details (brittle refactors)
- Single tests asserting multiple unrelated concerns (ambiguous failures)
- Using slow integration/E2E tests to validate pure logic that could be unit-tested

## Evidence Expectations

- Cite the test(s) and the production boundary they exercise (entry points, seams, adapters)
- For flakiness, cite the non-deterministic dependency (time/random/IO/order/shared state)
- For diagnosability issues, cite the failing assertion output or the overly broad test scope
