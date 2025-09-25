#!/bin/bash

# gemini.sh - Generate Gemini CLI slash commands from unified config
# Run from project root with: just cmn-slash-gemini

set -euo pipefail

CONFIG_FILE="config/common/aiding/slash/config.json"
GEMINI_COMMANDS_DIR="$HOME/.gemini/commands"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Create Gemini commands directory if ~/.gemini exists
if [[ -d "$HOME/.gemini" ]]; then
    mkdir -p "$GEMINI_COMMANDS_DIR"
else
    echo "Warning: ~/.gemini directory not found. Skipping Gemini command generation."
    exit 0
fi

# Remove existing command files
rm -f "$GEMINI_COMMANDS_DIR"/*.toml

echo "Generating Gemini CLI slash commands..."

# Parse config.json and generate command files
jq -r '.commands | to_entries[] | @base64' "$CONFIG_FILE" | while read -r row; do
    cmd=$(echo "$row" | base64 --decode | jq -r '.key')
    description_json=$(echo "$row" | base64 --decode | jq -r '.value.description | @json')
    prompt_file=$(echo "$row" | base64 --decode | jq -r '.value["prompt-file"]')
    output_file="$GEMINI_COMMANDS_DIR/$cmd.toml"

    # Start building the TOML file
    echo "description = $description_json" > "$output_file"
    echo "" >> "$output_file"
    echo "prompt = \"\"\"" >> "$output_file"

    # Add the prompt content from the referenced file
    if [[ -f "config/common/aiding/slash/$prompt_file" ]]; then
        cat "config/common/aiding/slash/$prompt_file" >> "$output_file"
        echo "" >> "$output_file"
        echo "" >> "$output_file"
        echo "!{{{args}}}" >> "$output_file"
    else
        echo "Error: Prompt file not found: config/common/aiding/slash/$prompt_file"
        exit 1
    fi

    echo "\"\"\"" >> "$output_file"

    echo "Generated: $output_file"
done

echo "Gemini CLI slash commands generated successfully!"