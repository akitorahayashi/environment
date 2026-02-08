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

# Link AGENTS.md to .claude/CLAUDE.md
alias cld-ln=cld_ln
cld_ln() {
	if [ ! -f "AGENTS.md" ]; then
		echo "❌ AGENTS.md not found in the project root. Please run this command from the repository root." >&2
		return 1
	fi

	# Ensure directory exists
	mkdir -p .claude

	# Create relative symlink (force overwrite)
	# Target: ../AGENTS.md (relative from .claude/CLAUDE.md)
	ln -sf ../AGENTS.md .claude/CLAUDE.md

	echo "🔗 Linked .claude/CLAUDE.md -> ../AGENTS.md"
}

alias cdx="codex"

alias cpt="copilot"

# Generate Gemini model aliases
eval "$(menv internal shell gen-gemini-aliases)"

# Basic gm alias
alias gm="gemini"
