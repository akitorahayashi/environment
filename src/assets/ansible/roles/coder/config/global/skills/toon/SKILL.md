---
name: toon
description: Use the TOON CLI when inspecting or producing substantial or repeatedly handled JSON-compatible structured data such as JSON files, API responses, database rows, search results, and structured logs, to reduce cumulative agent-context tokens.
---

# TOON

## Purpose

TOON is a temporary, lossless representation of the JSON data model for reducing the tokens required to read or produce structured data.

JSON remains the canonical interchange and file format unless the task explicitly requires TOON.

## Selection

Use TOON when JSON-compatible structured data is substantial or will be handled repeatedly during the session, especially uniform arrays of objects.

Judge benefit by repeated structure and expected cumulative context cost, not by a fixed row-count threshold. Small inputs can justify TOON when similar data will be read or produced repeatedly.

Keep JSON or use another suitable format when the data is one-off and trivially small, deeply nested, non-uniform, an array of arrays, or already a simple table better represented as CSV.

When the benefit is uncertain, compare token estimates without loading the source JSON into agent context:

```sh
mkdir -p .tmp
toon input.json --stats -o .tmp/input.toon
```

## Input Normalization

TOON accepts one JSON value, not newline-delimited JSON (NDJSON/JSONL). Slurp NDJSON into an array before encoding it:

```sh
jq -s '.' events.ndjson | toon
```

Reduce inputs to the required rows and fields before encoding when the task needs only part of the data:

```sh
jq '{items: [.items[] | {id, name, status}]}' response.json | toon
```

## Reading Structured Data

Read the CLI's TOON output instead of first reading the source JSON into agent context.

```sh
toon large-response.json
curl -fsSL https://api.example.com/items | toon
```

Persist converted data under the project-root `.tmp/` directory:

```sh
mkdir -p .tmp
toon large-response.json --stats -o .tmp/large-response.toon
```

Do not read both the complete source JSON and its TOON representation unless comparison is required by the task.

## Producing Structured Data

For substantial or repeatedly produced JSON-compatible output, author TOON in the project-root `.tmp/` directory and decode it with strict validation into another temporary file:

```sh
mkdir -p .tmp
output="$(mktemp .tmp/generated.XXXXXX)"
toon .tmp/generated.toon -o "$output"
```

For stdin, specify decode direction explicitly:

```sh
mkdir -p .tmp
output="$(mktemp .tmp/generated.XXXXXX)"
toon --decode -o "$output" < .tmp/generated.toon
```

Validate the decoded JSON syntax:

```sh
jq empty "$output"
```

`jq empty` proves only that the output is valid JSON. Run task-specific checks for required values, counts, and schema before moving it.

Move the output to the required path only after all validation succeeds:

```sh
mv "$output" generated.json
```

Treat the generated JSON as the deliverable unless the task explicitly requests TOON.

## Validation

The `toon` command uses strict decoding by default. Strict decoding validates array counts, indentation, headers, and escaping.

Always decode agent-authored TOON before using it as JSON. A decode failure means the TOON must be corrected.

Never decode directly to the final output path. The CLI can leave partial JSON output when strict decoding fails. Use a new temporary output for each decode, then move it to the final path only after decode and JSON validation succeed.

Do not use `--no-strict` to accept malformed agent-authored TOON. Surface missing CLI availability or conversion failures instead of silently falling back.

## Required Syntax

Objects use `key: value`, and nesting uses two-space indentation:

```toon
user:
  id: 1
  name: Alice
  active: true
```

Primitive arrays declare their element count:

```toon
tags[3]: rust,cli,macos
```

Uniform arrays of objects declare the row count and field order once:

```toon
users[2]{id,name,active}:
  1,Alice,true
  2,Bob,false
```

`[N]` is the array element count. `{fields}` defines the field order for every following row.

Quote strings that could be interpreted as another type or contain structural characters:

```toon
version: "123"
enabled: "true"
note: "hello, world"
```

Rely on strict decoding rather than manually reasoning about uncommon syntax and escaping cases.
