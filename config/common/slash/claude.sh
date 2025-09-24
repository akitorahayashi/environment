#!/bin/bash

# claude.sh - Generate Claude Code slash commands from unified config
# Run from project root with: just cmn-slash-claude

set -euo pipefail

CONFIG_FILE="config/common/slash/config.json"
CLAUDE_COMMANDS_DIR="$HOME/.claude/commands"

# Check if config file exists
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Create Claude commands directory if ~/.claude exists
if [[ -d "$HOME/.claude" ]]; then
    mkdir -p "$CLAUDE_COMMANDS_DIR"
else
    echo "Warning: ~/.claude directory not found. Skipping Claude command generation."
    exit 0
fi

# Remove existing command files
rm -f "$CLAUDE_COMMANDS_DIR"/*.md

echo "Generating Claude Code slash commands..."

# Parse config.json and generate command files
jq -r '.commands | to_entries[] | @base64' "$CONFIG_FILE" | while read -r row; do
    cmd=$(echo "$row" | base64 --decode | jq -r '.key')
    title=$(echo "$row" | base64 --decode | jq -r '.value.title')
    description=$(echo "$row" | base64 --decode | jq -r '.value.description')
    arg_hint=$(echo "$row" | base64 --decode | jq -r '.value["argument-hint"] // ""')
    prompt_file=$(echo "$row" | base64 --decode | jq -r '.value["prompt-file"]')
    output_file="$CLAUDE_COMMANDS_DIR/$cmd.md"

    # Start building the frontmatter
    echo "---" > "$output_file"
    echo "title: \"$title\"" >> "$output_file"

    # Add argument-hint if it exists
    if [[ -n "$arg_hint" ]]; then
        echo "argument-hint: \"$arg_hint\"" >> "$output_file"
    fi

    echo "---" >> "$output_file"
    echo "" >> "$output_file"

    # Add the prompt content from the referenced file
    if [[ -f "config/common/slash/$prompt_file" ]]; then
        cat "config/common/slash/$prompt_file" >> "$output_file"
    else
        echo "Error: Prompt file not found: config/common/slash/$prompt_file"
        exit 1
    fi

    echo "Generated: $output_file"
done

echo "Claude Code slash commands generated successfully!"