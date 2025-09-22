alias cld="claude"
alias cld-y="claude --dangerously-skip-permissions"

# MCP
alias cld-m-st="claude mcp serve"
alias cld-m-a="claude mcp add"
alias cld-m-rm="claude mcp remove"
alias cld-m-ls="claude mcp list"

# Claude Configuration Management
# Copy ~/.claude directory to current directory for local configuration
claude-lk() {
    if [ ! -d ~/.claude ]; then
        echo "Error: ~/.claude directory not found"
        return 1
    fi

    if [ -d .claude ]; then
        echo ".claude directory already exists in current directory"
        return 1
    fi

    cp -r ~/.claude .claude
    echo "✅ Created .claude directory in current directory from ~/.claude"
}