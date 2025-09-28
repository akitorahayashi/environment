#!/bin/bash

# codex.sh - Generate Codex slash commands from unified config
# Run from project root with: just cmn-slash-codex

set -euo pipefail

CONFIG_FILE="config/common/aiding/slash/config.json"
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
jq -r '.commands | to_entries[] | @base64' "$CONFIG_FILE" | while read -r row; do
    cmd=$(echo "$row" | base64 --decode | jq -r '.key')
    prompt_file=$(echo "$row" | base64 --decode | jq -r '.value["prompt-file"]')
    output_file="$CODEX_PROMPTS_DIR/$cmd.md"

    # Add the prompt content from the referenced file
    if [[ -f "config/common/aiding/slash/$prompt_file" ]]; then
        cat "config/common/aiding/slash/$prompt_file" > "$output_file"
    else
        echo "Error: Prompt file not found: config/common/aiding/slash/$prompt_file" >&2
        exit 1
    fi
done
