#!/bin/bash
alias cdx="codex"

# Codex Configuration Management
# Initialize project-specific Codex configuration
cdx-ini() {
	# Guard clause: Verify prerequisites
	if [ -d .codex ]; then
		echo "❌ .codex directory already exists in current directory"
		return 1
	fi

	# Build basic structure
	mkdir -p .codex

	echo "✅ Initialized project-specific .codex configuration"
}
