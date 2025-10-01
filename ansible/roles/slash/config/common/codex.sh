#!/bin/bash

# codex.sh - Generate Codex slash commands from unified config
# Run from project root as part of: just cmn-codex

set -euo pipefail

CONFIG_FILE="ansible/roles/slash/config/common/config.json"
CODEX_PROMPTS_DIR="$HOME/.codex/prompts"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE" >&2
    exit 1
fi

# Create Codex prompts directory
mkdir -p "$CODEX_PROMPTS_DIR"

# Remove existing command files
rm -f "$CODEX_PROMPTS_DIR"/*

# Parse config.json and generate command files
while IFS=$'\t' read -r cmd prompt_file; do
    # Sanitize command key to a safe filename
    safe_cmd="${cmd//[^A-Za-z0-9._-]/_}"
    if [[ "$safe_cmd" != "$cmd" ]]; then
        echo "Error: Invalid command key '$cmd' (unsafe filename)." >&2
        exit 1
    fi
    output_file="$CODEX_PROMPTS_DIR/$safe_cmd.md"
    prompt_source_path="ansible/roles/slash/config/common/$prompt_file"

    # Add the prompt content from the referenced file
    if [[ -f "$prompt_source_path" ]]; then
        cat "$prompt_source_path" > "$output_file"
    else
        echo "Error: Prompt file not found: $prompt_source_path" >&2
        exit 1
    fi
done < <(jq -r '.commands | to_entries[] | select(.value["prompt-file"]) | "\(.key)\t\(.value["prompt-file"])"' "$CONFIG_FILE")
