alias cld="claude"
alias cld-y="claude --dangerously-skip-permissions"
alias cld-p="claude --print"
alias cld-yp="claude --dangerously-skip-permissions --print"

# MCP
alias cld-m-st="claude mcp serve"
alias cld-m-a="claude mcp add"
alias cld-m-rm="claude mcp remove"
alias cld-m-ls="claude mcp list"

# Claude Configuration Management
# Initialize project-specific Claude configuration
cld-ini() {
    if [ ! -d ~/.claude ]; then
        echo "Error: ~/.claude directory not found"
        return 1
    fi

    if [ -d .claude ]; then
        echo ".claude directory already exists in current directory"
        return 1
    fi

    # Create .claude directory
    mkdir -p .claude/commands

    # Copy project-specific files only
    if [ -d ~/.claude/commands ] && [ "$(ls -A ~/.claude/commands)" ]; then
        cp ~/.claude/commands/* .claude/commands/
    fi

    if [ -f ~/.claude/settings.json ]; then
        cp ~/.claude/settings.json .claude/settings.json
    fi

    if [ -f ~/.claude/CLAUDE.md ]; then
        cp ~/.claude/CLAUDE.md .claude/CLAUDE.md
    fi

    echo "✅ Initialized project-specific .claude configuration"
}