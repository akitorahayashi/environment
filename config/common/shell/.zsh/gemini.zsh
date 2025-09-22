alias gmn="gemini"

# MCP
alias gmn-m-a="gemini mcp add"
alias gmn-m-rm="gemini mcp remove"
alias gmn-m-ls="gemini mcp list"

# Highest performance
alias gmn-pr="gemini -m gemini-2.5-pro"
alias gmn-pr-y="gemini -m gemini-2.5-pro -y"
alias gmn-pr-p="gemini -m gemini-2.5-pro -p"
alias gmn-pr-a-p="gemini -a -m gemini-2.5-pro -p"

# Cost-performance balance priority
alias gmn-fl="gemini -m gemini-2.5-flash"
alias gmn-fl-y="gemini -m gemini-2.5-flash -y"
alias gmn-fl-p="gemini -m gemini-2.5-flash -p"
alias gmn-fl-a-p="gemini -a -m gemini-2.5-flash -p"

# Lightweight
alias gmn-lt="gemini -m gemini-2.5-flash-lite"
alias gmn-lt-y="gemini -m gemini-2.5-flash-lite -y"
alias gmn-lt-p="gemini -m gemini-2.5-flash-lite -p"
alias gmn-lt-a-p="gemini -a -m gemini-2.5-flash-lite -p"

# Image generation
alias gmn-i="gemini -m gemini-2.5-flash-image-preview"
alias gmn-i-y="gemini -m gemini-2.5-flash-image-preview -y"
alias gmn-i-p="gemini -m gemini-2.5-flash-image-preview -p"
alias gmn-i-a-p="gemini -a -m gemini-2.5-flash-image-preview -p"

# Image generation with live preview
alias gmn-il="gemini -m gemini-2.5-flash-image-live-preview"
alias gmn-il-y="gemini -m gemini-2.5-flash-image-live-preview -y"
alias gmn-il-p="gemini -m gemini-2.5-flash-image-live-preview -p"
alias gmn-il-a-p="gemini -a -m gemini-2.5-flash-image-live-preview -p"

# gemini command options
# -p, --prompt: Specify a prompt. Appended to input on stdin (if any). Used in non-interactive mode.
# -a, --all-files: Include ALL files in context?
# -y, --yolo: Automatically accept all actions (aka YOLO mode).

# Gemini Configuration Management
# Initialize project-specific Gemini configuration
gmn-ini() {
    if [ ! -d ~/.gemini ]; then
        echo "Error: ~/.gemini directory not found"
        return 1
    fi

    if [ -d .gemini ]; then
        echo ".gemini directory already exists in current directory"
        return 1
    fi

    # Create .gemini directory
    mkdir -p .gemini/commands

    # Copy project-specific files only
    if [ -f ~/.gemini/settings.json ]; then
        cp ~/.gemini/settings.json .gemini/settings.json
    fi

    if [ -d ~/.gemini/commands ] && [ "$(ls -A ~/.gemini/commands)" ]; then
        cp ~/.gemini/commands/* .gemini/commands/
    fi

    if [ -f ~/.gemini/GEMINI.md ]; then
        cp ~/.gemini/GEMINI.md .gemini/GEMINI.md
    fi

    if [ -f ~/.gemini/sandbox.Dockerfile ]; then
        cp ~/.gemini/sandbox.Dockerfile .gemini/sandbox.Dockerfile
    fi

    echo "✅ Initialized project-specific .gemini configuration"
}