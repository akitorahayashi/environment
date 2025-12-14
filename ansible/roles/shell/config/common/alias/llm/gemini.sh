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

	# Link AGENTS.md immediately
	gm_ln

	echo "✅ Initialized project-specific .gemini configuration"
}

# Link AGENTS.md to .gemini/GEMINI.md
alias gm-ln=gm_ln
gm_ln() {
	if [ ! -f "AGENTS.md" ]; then
		echo "❌ AGENTS.md not found in the project root. Please run this command from the repository root." >&2
		return 1
	fi

	# Ensure directory exists
	mkdir -p .gemini

	# Create relative symlink (force overwrite)
	# Target: ../AGENTS.md (relative from .gemini/GEMINI.md)
	ln -sf ../AGENTS.md .gemini/GEMINI.md

	echo "🔗 Linked .gemini/GEMINI.md -> ../AGENTS.md"
}
