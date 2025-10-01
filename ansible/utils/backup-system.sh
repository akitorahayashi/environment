#!/bin/bash
set -euo pipefail

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# ================================================
# Initial setup and file path configuration
# ================================================

INPUT_DEFINITIONS_DIR="$CONFIG_DIR_PROPS/definitions"
OUTPUT_FILE="$CONFIG_DIR_PROPS/system.yml"

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo "[ERROR] yq is not installed. Please install it (e.g., 'brew install yq')" >&2
    exit 1
fi

OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"

echo "Retrieving current macOS system defaults and generating $OUTPUT_FILE..."

# Remove existing system defaults file
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
    echo "Removed existing system defaults file: $OUTPUT_FILE"
fi

# Start YAML array
cat <<EOF > "$OUTPUT_FILE"
---
EOF

# ================================================
# Utility function definitions
# ================================================

# Function to get value and fallback to default if it doesn't exist
get_default_value() {
    local value
    value=$(defaults read "$1" "$2" 2>/dev/null) || value="$3"
    echo "$value"
}

# Function to convert bool values to appropriate format
format_bool_value() {
    local value
    value="$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)"
    case "$value" in
        1|true) echo "true" ;;
        0|false) echo "false" ;;
        *) echo "$value" ;;
    esac
}

# Function to add YAML setting
add_yaml_setting() {
    local key="$1"
    local domain="$2"
    local type="$3"
    local value="$4"
    local comment="$5"

    if [ -n "$comment" ]; then
        echo "  # ${comment}" >> "$OUTPUT_FILE"
    fi

    if [ "$domain" = "NSGlobalDomain" ]; then
        echo "- { key: '${key}', type: '${type}', value: ${value} }" >> "$OUTPUT_FILE"
    else
        echo "- { key: '${key}', domain: '${domain}', type: '${type}', value: ${value} }" >> "$OUTPUT_FILE"
    fi
}

# ================================================
# YAML setting generation
# ================================================

# Process all settings from the YAML files in the directory
find "$INPUT_DEFINITIONS_DIR" -name "*.yml" | while read -r file; do
    yq -r '.[] | [.key, .domain // "NSGlobalDomain", .type, .default // "", .comment // ""] | @tsv' "$file" | \
    while IFS=$'\t' read -r key domain type default_val comment; do
    # Handle special cases for value retrieval
    if [[ "$key" == "com.apple.keyboard.fnState" ]] || [[ "$key" == "com.apple.trackpad.scaling" ]] || [[ "$key" == "com.apple.sound.beep.feedback" ]] || [[ "$key" == "com.apple.sound.beep.sound" ]]; then
        # These keys use -g flag
        value=$(get_default_value -g "$key" "$default_val")
    else
        # Standard defaults read
        value=$(get_default_value "$domain" "$key" "$default_val")
    fi

    # Format the value based on type
    case "$type" in
        "bool")
            formatted_value="$(format_bool_value "$value")"
            ;;
        "string")
            # Special case for screenshot location - apply HOME substitution
            if [[ "$key" == "location" ]]; then
                value_escaped="${value/#$HOME/\$HOME}"
                formatted_value="'$value_escaped'"
            else
                formatted_value="'$value'"
            fi
            ;;
        *)
            formatted_value="$value"
            ;;
    esac

    # Add the setting to YAML
    add_yaml_setting "$key" "$domain" "$type" "$formatted_value" "$comment"
done
done

echo "Generated system defaults script: $OUTPUT_FILE"
