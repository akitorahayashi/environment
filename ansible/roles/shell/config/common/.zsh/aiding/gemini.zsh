#!/bin/zsh
# shellcheck disable=SC1103,SC2296,SC2139
# Generate Gemini model aliases
_generate_gemini_aliases() {
    local -A models=(
        [pr]="gemini-2.5-pro"
        [fl]="gemini-2.5-flash"
        [lt]="gemini-2.5-flash-lite"
        [i]="gemini-2.5-flash-image-preview"
        [il]="gemini-2.5-flash-image-live-preview"
    )

    local -A options=(
        [""]=""
        [y]="-y"
        [p]="-p"
        [ap]="-a -p"
        [yp]="-y -p"
        [yap]="-y -a -p"
    )

    local model_key opts_key alias_name
    for model_key in ${(k)models}; do
        for opts_key in ${(k)options}; do
            alias_name="gm-${model_key}${opts_key:+-}${opts_key}"

            alias "$alias_name"="gemini -m \${models[\$model_key]} \${options[\$opts_key]}"
        done
    done
}

_generate_gemini_aliases

# Basic gm alias (defaults to flash model)
alias gm="gemini -m gemini-2.5-flash"

# Plain model aliases (without options)
alias gm-pr="gemini -m gemini-2.5-pro"
alias gm-fl="gemini -m gemini-2.5-flash"
alias gm-lt="gemini -m gemini-2.5-flash-lite"
alias gm-i="gemini -m gemini-2.5-flash-image-preview"
alias gm-il="gemini -m gemini-2.5-flash-image-live-preview"

# gemini command options
# -p, --prompt: Specify a prompt. Appended to input on stdin (if any). Used in non-interactive mode.
# -a, --all-files: Include ALL files in context?
# -y, --yolo: Automatically accept all actions (aka YOLO mode).

# Gemini Configuration Management
# Initialize project-specific Gemini configuration
gm-ini() {
    # Guard clause: Verify prerequisites
    if [ -d .gemini ]; then
        echo "❌ .gemini directory already exists in current directory"
        return 1
    fi

    # Build basic structure
    mkdir -p .gemini/commands

    # Generate initial configuration file
    echo '{}' > .gemini/settings.json
    touch .gemini/GEMINI.md

    echo "✅ Initialized project-specific .gemini configuration"
}

# Link MCP configuration from root .mcp.json to .gemini/settings.json
gm-mcp-ln() {
    local project_root
    project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
    local mcp_json="${project_root}/.mcp.json"
    local gemini_dir=".gemini"
    local gemini_settings="${gemini_dir}/settings.json"

    # Create .gemini directory if it doesn't exist
    if [ ! -d "$gemini_dir" ]; then
        mkdir -p "$gemini_dir"
        echo "📁 Created .gemini directory"
    fi

    # Initialize settings.json if it doesn't exist
    if [ ! -f "$gemini_settings" ]; then
        echo '{"mcpServers": {}}' > "$gemini_settings"
        echo "📄 Created .gemini/settings.json"
    fi

    # Check if .mcp.json exists in project root
    if [ ! -f "$mcp_json" ]; then
        echo "❌ No .mcp.json found in project root: $project_root"
        return 1
    fi

    # Read .mcp.json content and extract servers
    if ! command -v jq >/dev/null 2>&1; then
        echo "❌ jq is required but not installed"
        return 1
    fi

    # Extract mcpServers from .mcp.json and merge into .gemini/settings.json
    local mcp_servers
    mcp_servers=$(jq -r '.mcpServers // {}' "$mcp_json" 2>/dev/null)

    if ! jq -r '.mcpServers // {}' "$mcp_json" >/dev/null 2>&1 || [ "$mcp_servers" = "null" ]; then
        echo "❌ Failed to parse .mcp.json or no mcpServers found"
        return 1
    fi

    # Update .gemini/settings.json with mcpServers from .mcp.json
    local temp_file
    temp_file=$(mktemp)
    jq --argjson servers "$mcp_servers" '.mcpServers = $servers' "$gemini_settings" > "$temp_file"

    if jq --argjson servers "$mcp_servers" '.mcpServers = $servers' "$gemini_settings" > "$temp_file"; then
        mv "$temp_file" "$gemini_settings"
        echo "✅ Synced mcpServers from $mcp_json to $gemini_settings"
        echo "📊 Servers configured: $(echo "$mcp_servers" | jq -r 'keys | join(", ")')"
    else
        rm -f "$temp_file"
        echo "❌ Failed to update .gemini/settings.json"
        return 1
    fi
}