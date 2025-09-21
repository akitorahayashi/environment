alias cld="claude"

# Update Claude MCP servers configuration
cld-u-mcp() {
  local mcp_config_file="$1"
  local claude_config_file="${HOME}/.claude.json"

  # Check if argument is provided
  if [[ -z "$mcp_config_file" ]]; then
    echo "Usage: cld-u-mcp <mcp-config-file>"
    echo "Example: cld-u-mcp config/common/claude/mcp-servers.json"
    return 1
  fi

  # Convert relative path to absolute if needed
  if [[ "$mcp_config_file" != /* ]]; then
    mcp_config_file="${PWD}/${mcp_config_file}"
  fi

  # Check if MCP config file exists
  if [[ ! -f "$mcp_config_file" ]]; then
    echo "Error: MCP config file not found: $mcp_config_file"
    return 1
  fi

  # Validate JSON format
  if ! jq empty "$mcp_config_file" 2>/dev/null; then
    echo "Error: Invalid JSON format in $mcp_config_file"
    return 1
  fi

  # Check if mcpServers key exists
  if ! jq -e ".mcpServers" "$mcp_config_file" >/dev/null 2>&1; then
    echo "Error: mcpServers key not found in $mcp_config_file"
    return 1
  fi

  # Validate MCP server structure
  local validation_result=$(jq -r "
    .mcpServers | to_entries[] |
    select(.value | has(\"type\") and has(\"command\") and has(\"args\") | not) |
    .key
  " "$mcp_config_file")

  if [[ -n "$validation_result" ]]; then
    echo "Error: Invalid MCP server configuration. Missing required fields (type, command, args) in servers:"
    echo "$validation_result"
    return 1
  fi

  # Read MCP servers from configuration
  local mcp_servers=$(jq ".mcpServers" "$mcp_config_file")

  # Check if ~/.claude.json exists
  local existing_config="{}"
  if [[ -f "$claude_config_file" ]]; then
    existing_config=$(cat "$claude_config_file")
  fi

  # Parse existing mcpServers or set to empty object
  local existing_mcp_servers=$(echo "$existing_config" | jq ".mcpServers // {}")

  # Check if MCP servers need updating
  if [[ "$existing_mcp_servers" != "$mcp_servers" ]]; then
    # Merge MCP servers into existing config
    local updated_config=$(echo "$existing_config" | jq ". + {\"mcpServers\": $mcp_servers}")

    # Write updated config
    echo "$updated_config" | jq . > "$claude_config_file"
    echo "Claude MCP servers configuration updated successfully."
  else
    echo "Claude MCP servers configuration is already up to date."
  fi
}