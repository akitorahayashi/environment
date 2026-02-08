---
name: svo-cli-design
description: Design CLI surfaces with SVO model (subcommand + object + args). Prevents mandatory-option sprawl, preserves positional-required inputs, keeps hierarchies shallow.
---

# SVO CLI Design

## Core Objective

SVO shape first. Required inputs as positional args. Mandatory options are exceptions only.

## Decision Workflow

1. **Semantic sentence**: `verb object required-inputs`
2. **Required inputs**: Positional args by default
3. **Options**: Ancillary modifiers, output modes, safety flags only. Reject duplicates of required meaning.
4. **Mandatory options** allowed only when:
   - Order-independence needed
   - Repeated keyed input needed
   - Payload too large/externalized
   - Omission is normal (explicit toggle safer)
5. **Command tree**: Shallow depth, stable vocabulary, no synonyms
6. **Aliases**: Provide short forms for commands and options (e.g., `init`→`i`, `update`→`u`, `--output`→`-o`)
7. **Operational contracts**:
   - `stdout`: result data
   - `stderr`: warnings/logs/errors
   - `--json`: machine output when needed
8. **Destructive ops**: Require confirmation/dry-run, `--yes`/`--force` override, `stderr` warning, non-zero exit on failure

## Existing CLI Rule

Current CLI is baseline. Propose deltas only. Redesign only if integration impossible.

## Review Output

Return: **Decision** (apply/modify/reject), **Reason** (purpose-driven), **Delta** (concrete changes), **Risk** (compatibility/UX).
