# MCP Configuration Management
# Create a local .mcp.json file in the current directory with the contents of ~/.mcp.json

mcp-lk() {
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