alias gm="gemini"

# MCP aliases
alias gm-m-a="gemini mcp add"
alias gm-m-rm="gemini mcp remove"
alias gm-m-ls="gemini mcp list"

# Generate Gemini model aliases
_generate_gemini_aliases() {
    local -A models=(
        [pr]="gemini-2.5-pro"
        [fl]="gemini-2.5-flash"
        [lt]="gemini-2.5-flash-lite"
        [i]="gemini-2.5-flash-image-preview"
        [il]="gemini-2.5-flash-image-live-preview"
    )

    local -A options=(
        [""]=""
        [y]="-y"
        [p]="-p"
        [ap]="-a -p"
        [yp]="-y -p"
        [yap]="-y -a -p"
    )

    local model_key opts_key
    for model_key in ${(k)models}; do
        for opts_key in ${(k)options}; do
            alias "gm-${model_key}-${opts_key}"="gemini -m ${models[$model_key]} ${options[$opts_key]}"
        done
    done
}

_generate_gemini_aliases

# gemini command options
# -p, --prompt: Specify a prompt. Appended to input on stdin (if any). Used in non-interactive mode.
# -a, --all-files: Include ALL files in context?
# -y, --yolo: Automatically accept all actions (aka YOLO mode).

# Initialize project-specific Gemini configuration
gm-ini() {
    local local_gemini=".gemini"

    # Validation
    [[ -d "$local_gemini" ]] && { echo "❌ $local_gemini already exists"; return 1; }

    # Create directory structure
    mkdir -p "$local_gemini/commands"

    # Create empty settings.json only
    echo '{}' > "$local_gemini/settings.json"

    echo "✅ Initialized .gemini configuration (empty settings.json created)"
}