# =============================================================================
# Zsh Prompt Configuration File Rules
# =============================================================================
#
# This file defines aliases for quickly copying lightweight prompts to interact with AI assistants.
#
# Rules:
# - Alias names: Short, descriptive (e.g., sum-f, translate-en)
# - Prompt format: Action-oriented, concise (e.g., "Translate to English:")
# - Prompts must be in English
# - Implementation: Use copy_prompt function with prompt as argument
# - Do not delete or modify these rules
#
# =============================================================================

# Function to copy prompt to clipboard and show success message
copy_prompt() {
    local prompt="$1"
    echo "$prompt" | pbcopy
    echo "✅ Copied \"$prompt\" to clipboard"
}

alias sm-f="copy_prompt 'Summarize this file'"
alias sm-p="copy_prompt 'Summarize this project'"

alias tr-e="copy_prompt 'Translate to English in up to 3 patterns'"
alias tr-j="copy_prompt 'Translate to Japanese in up to 3 patterns'"

