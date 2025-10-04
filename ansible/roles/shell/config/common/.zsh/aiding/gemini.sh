#!/bin/sh
# Generate Gemini model aliases
eval "$(gen_gemini_aliases.py)"

# Basic gm alias (defaults to flash model)
alias gm="gemini -m gemini-2.5-flash"

# Gemini Configuration Management
# Initialize project-specific Gemini configuration
alias gm-ini=gm_ini
gm_ini() {
	# Guard clause: Verify prerequisites
	if [ -d .gemini ]; then
		echo "❌ .gemini directory already exists in current directory"
		return 1
	fi

	# Build basic structure
	mkdir -p .gemini/commands

	# Generate initial configuration file
	echo '{}' >.gemini/settings.json
	touch .gemini/GEMINI.md

	echo "✅ Initialized project-specific .gemini configuration"
}

# Link MCP configuration from root .mcp.json to .gemini/settings.json
alias gm-mcp-ln=gm_mcp_ln
gm_mcp_ln() {
	command gm_mcp_ln.py "$@"
}
