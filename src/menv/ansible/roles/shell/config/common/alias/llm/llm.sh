#!/bin/bash
alias cld="claude"
alias cld-y="claude --dangerously-skip-permissions"
alias cld-p="claude --print"
alias cld-yp="claude --dangerously-skip-permissions --print"

alias agy="antigravity"
alias agy-r="antigravity --reuse-window"
alias agy-n="antigravity --new-window"

# MCP
alias cld-m-st="claude mcp serve"
alias cld-m-a="claude mcp add"
alias cld-m-rm="claude mcp remove"
alias cld-m-ls="claude mcp list"

# Link AGENTS.md or README.md to .claude/CLAUDE.md
alias cld-ln=cld_ln
cld_ln() {
	local target_file="AGENTS.md"
	if [ ! -f "AGENTS.md" ]; then
		if [ -f "README.md" ]; then
			target_file="README.md"
		else
			echo "❌ Neither AGENTS.md nor README.md found in the project root. Please run this command from the repository root." >&2
			return 1
		fi
	fi

	# Ensure directory exists
	mkdir -p .claude

	# Create relative symlink (force overwrite)
	# Target: ../<target_file> (relative from .claude/CLAUDE.md)
	ln -sf "../${target_file}" .claude/CLAUDE.md

	echo "🔗 Linked .claude/CLAUDE.md -> ../${target_file}"
}

alias cdx="codex"

alias cpt="copilot"

# Generate Gemini model aliases
eval "$(menv internal shell gen-gemini-aliases)"

# Basic gm alias
alias gm="gemini"
