#!/bin/bash
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
	# Guard clause: Verify prerequisites
	if [ -d .claude ]; then
		echo "❌ .claude directory already exists in current directory"
		return 1
	fi

	# Build basic structure
	mkdir -p .claude/commands

	# Generate initial configuration file
	echo '{}' >.claude/settings.json
	touch .claude/CLAUDE.md

	echo "✅ Initialized project-specific .claude configuration"
}
