#!/bin/bash
alias cpt="copilot"

# Copilot Configuration Management
# Initialize project-specific Copilot configuration
cpt-ini() {
	# Guard clause: Verify prerequisites
	# Note: We check if the file exists, not just the directory, as .github is common
	if [ -f .github/copilot-instructions.md ]; then
		echo "❌ .github/copilot-instructions.md already exists"
		return 1
	fi

	# Build basic structure
	mkdir -p .github

	# Link AGENTS.md
	cpt_ln

	echo "✅ Initialized project-specific Copilot instructions (.github/copilot-instructions.md)"
}

# Link AGENTS.md to .github/copilot-instructions.md
alias cpt-ln=cpt_ln
cpt_ln() {
	if [ ! -f "AGENTS.md" ]; then
		echo "❌ AGENTS.md not found in the project root. Please run this command from the repository root." >&2
		return 1
	fi

	# Ensure directory exists
	mkdir -p .github

	# Create relative symlink (force overwrite)
	# Target: ../AGENTS.md (relative from .github/copilot-instructions.md)
	ln -sf ../AGENTS.md .github/copilot-instructions.md

	echo "🔗 Linked .github/copilot-instructions.md -> ../AGENTS.md"
}
