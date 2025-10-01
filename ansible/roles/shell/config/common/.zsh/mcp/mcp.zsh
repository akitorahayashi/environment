# MCP Configuration Management
# Create a local .mcp.json file in the current directory with the contents of ~/.mcp.json

# Private validation functions
_mcp_validate_server_name() {
    if [ -z "$1" ]; then
        echo "Error: MCP server name is required"
        echo "Usage: $2 <mcp-server-name>"
        return 1
    fi
}

_mcp_validate_local_config() {
    if [ ! -f .mcp.json ]; then
        echo "Error: .mcp.json file not found in current directory"
        [ "$1" = "suggest_init" ] && echo "Run 'mcp-ini' first to create .mcp.json"
        return 1
    fi
}

_mcp_validate_global_config() {
    if [ ! -f ~/.mcp.json ]; then
        echo "Error: ~/.mcp.json file not found"
        return 1
    fi
}

_mcp_server_exists_global() {
    local mcp_name="$1"
    local server_exists=$(jq -r ".mcpServers | has(\"$mcp_name\")" ~/.mcp.json 2>/dev/null)
    [ "$server_exists" = "true" ]
}

_mcp_server_exists_local() {
    local mcp_name="$1"
    local server_exists=$(jq -r ".mcpServers | has(\"$mcp_name\")" .mcp.json 2>/dev/null)
    [ "$server_exists" = "true" ]
}

_mcp_show_available_servers() {
    local config_file="$1"
    echo "Available servers:"
    jq -r '.mcpServers | keys[]' "$config_file" 2>/dev/null
}

mcp-ini() {
    if [ -f .mcp.json ]; then
        echo ".mcp.json file already exists in current directory"
        return 1
    fi

    echo '{"mcpServers": {}}' > .mcp.json
    echo "✅ Created .mcp.json with mcpServers key in current directory"
}

mcp-ini-f() {
    if [ ! -f ~/.mcp.json ]; then
        echo "Error: ~/.mcp.json file not found"
        return 1
    fi

    if [ -f .mcp.json ]; then
        echo ".mcp.json file already exists in current directory"
        return 1
    fi

    cp ~/.mcp.json .mcp.json
    echo "✅ Created .mcp.json in current directory from ~/.mcp.json"
}

mcp-ls() {
    if [ ! -f ~/.mcp.json ]; then
        echo "Error: ~/.mcp.json file not found"
        return 1
    fi

    echo "Available MCP servers:"
    echo "====================="

    # Get all MCP server names
    local mcp_names=$(jq -r '.mcpServers | keys[]' ~/.mcp.json 2>/dev/null)

    if [ -z "$mcp_names" ]; then
        echo "No MCP servers found in ~/.mcp.json"
        return 1
    fi

    # Loop through each MCP server and display its info
    echo "$mcp_names" | while read -r mcp_name; do
        local command=$(jq -r ".mcpServers[\"$mcp_name\"].command" ~/.mcp.json 2>/dev/null)
        local args=$(jq -r ".mcpServers[\"$mcp_name\"].args[]?" ~/.mcp.json 2>/dev/null | tr '\n' ' ')

        if [ "$command" != "null" ]; then
            local full_command="$command"
            if [ -n "$args" ]; then
                full_command="$command $args"
            fi

            echo "[$mcp_name]"
            echo "$full_command"

            # Try to get description from ~/.mcp.json
            local description=$(jq -r ".mcpServers[\"$mcp_name\"].description // \"No description available\"" ~/.mcp.json 2>/dev/null)
            echo "- $description"
            echo ""
        else
            echo "[$mcp_name]: No command found"
            echo ""
        fi
    done
}

mcp-a() {
    _mcp_validate_server_name "$1" "mcp-a" || return 1
    _mcp_validate_local_config "suggest_init" || return 1
    _mcp_validate_global_config || return 1

    local mcp_name="$1"

    if ! _mcp_server_exists_global "$mcp_name"; then
        echo "Error: MCP server '$mcp_name' not found in ~/.mcp.json"
        _mcp_show_available_servers ~/.mcp.json
        return 1
    fi

    if _mcp_server_exists_local "$mcp_name"; then
        echo "Error: MCP server '$mcp_name' already exists in local .mcp.json"
        return 1
    fi

    # Extract server configuration from global config
    local server_config=$(jq -r ".mcpServers[\"$mcp_name\"]" ~/.mcp.json 2>/dev/null)

    if [ "$server_config" = "null" ]; then
        echo "Error: No configuration found for MCP server '$mcp_name'"
        return 1
    fi

    # Add server to local .mcp.json
    jq --arg name "$mcp_name" --argjson cfg "$server_config" \
       '.mcpServers[$name] = $cfg' \
       .mcp.json > .mcp.json.tmp && mv .mcp.json.tmp .mcp.json

    echo "✅ Added MCP server '$mcp_name' to local .mcp.json"
}

mcp-rm() {
    _mcp_validate_server_name "$1" "mcp-rm" || return 1
    _mcp_validate_local_config || return 1

    local mcp_name="$1"

    if ! _mcp_server_exists_local "$mcp_name"; then
        echo "Error: MCP server '$mcp_name' not found in local .mcp.json"
        echo "Available servers in local config:"
        _mcp_show_available_servers .mcp.json
        return 1
    fi

    # Remove server from local .mcp.json
    jq "del(.mcpServers[\"$mcp_name\"])" .mcp.json > .mcp.json.tmp && mv .mcp.json.tmp .mcp.json

    echo "✅ Removed MCP server '$mcp_name' from local .mcp.json"
}

mcp-cmd() {
    _mcp_validate_server_name "$1" "mcp-cmd" || return 1
    _mcp_validate_global_config || return 1

    local mcp_name="$1"

    if ! _mcp_server_exists_global "$mcp_name"; then
        echo "Error: MCP server '$mcp_name' not found in ~/.mcp.json"
        _mcp_show_available_servers ~/.mcp.json
        return 1
    fi

    # Extract command and args
    local command=$(jq -r ".mcpServers[\"$mcp_name\"].command" ~/.mcp.json 2>/dev/null)
    local args=$(jq -r ".mcpServers[\"$mcp_name\"].args[]?" ~/.mcp.json 2>/dev/null | tr '\n' ' ')

    if [ "$command" = "null" ]; then
        echo "Error: No command found for MCP server '$mcp_name'"
        return 1
    fi

    # Build and display the command
    local full_command="$command"
    if [ -n "$args" ]; then
        full_command="$command $args"
    fi

    echo "Command for '$mcp_name': $full_command"

    # Copy to clipboard in format: "name command"
    local add_format="$mcp_name $full_command"
    echo "$add_format" | pbcopy
    echo "📋 Copied to clipboard: $add_format"
}

