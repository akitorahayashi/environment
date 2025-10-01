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

# Create Claude commands directory
mkdir -p "$CLAUDE_COMMANDS_DIR"

# Remove existing command files
rm -f "$CLAUDE_COMMANDS_DIR"/*

# Parse config.json and generate command files
jq -r '.commands | to_entries[] | @base64' "$CONFIG_FILE" | while read -r row; do
    cmd=$(echo "$row" | base64 --decode | jq -r '.key')
    title=$(echo "$row" | base64 --decode | jq -r '.value.title')
    description=$(echo "$row" | base64 --decode | jq -r '.value.description')
    prompt_file=$(echo "$row" | base64 --decode | jq -r '.value["prompt-file"]')
    output_file="$CLAUDE_COMMANDS_DIR/$cmd.md"

    # Start building the frontmatter
    {
        echo "---"
        echo "title: \"$title\""
        echo "description: \"$description\""
        echo "---"
        echo ""
    } > "$output_file"

    # Add the prompt content from the referenced file
    if [[ -f "config/common/slash/$prompt_file" ]]; then
        cat "config/common/slash/$prompt_file" >> "$output_file"
    else
        echo "Error: Prompt file not found: config/common/slash/$prompt_file"
        exit 1
    fi
done
