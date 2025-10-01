#!/bin/bash
alias cpt="copilot"

# Copilot Configuration Management
# Initialize project-specific Copilot configuration
cpt-ini() {
	# Guard clause: Verify prerequisites
	if [ -d .github ]; then
		echo "❌ .github directory already exists in current directory"
		return 1
	fi

	# Build basic structure
	mkdir -p .github

	# Generate initial configuration file
	touch .github/copilot-instructions.md

	echo "✅ Initialized project-specific .copilot configuration"
}
