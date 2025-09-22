alias gm="gemini"

# Highest performance
alias gm-pr="gemini -m gemini-2.5-pro"
alias gm-pr-y="gemini -m gemini-2.5-pro -y"
alias gm-pr-p="gemini -m gemini-2.5-pro -p"
alias gm-pr-a-p="gemini -a -m gemini-2.5-pro -p"

# Cost-performance balance priority
alias gm-fl="gemini -m gemini-2.5-flash"
alias gm-fl-y="gemini -m gemini-2.5-flash -y"
alias gm-fl-p="gemini -m gemini-2.5-flash -p"
alias gm-fl-a-p="gemini -a -m gemini-2.5-flash -p"

# Lightweight
alias gm-lt="gemini -m gemini-2.5-flash-lite"
alias gm-lt-y="gemini -m gemini-2.5-flash-lite -y"
alias gm-lt-p="gemini -m gemini-2.5-flash-lite -p"
alias gm-lt-a-p="gemini -a -m gemini-2.5-flash-lite -p"

# Image generation
alias gm-i="gemini -m gemini-2.5-flash-image-preview"
alias gm-i-y="gemini -m gemini-2.5-flash-image-preview -y"
alias gm-i-p="gemini -m gemini-2.5-flash-image-preview -p"
alias gm-i-a-p="gemini -a -m gemini-2.5-flash-image-preview -p"

# Image generation with live preview
alias gm-il="gemini -m gemini-2.5-flash-image-live-preview"
alias gm-il-y="gemini -m gemini-2.5-flash-image-live-preview -y"
alias gm-il-p="gemini -m gemini-2.5-flash-image-live-preview -p"
alias gm-il-a-p="gemini -a -m gemini-2.5-flash-image-live-preview -p"

# gemini command options
# -p, --prompt: Specify a prompt. Appended to input on stdin (if any). Used in non-interactive mode.
# -a, --all-files: Include ALL files in context?
# -y, --yolo: Automatically accept all actions (aka YOLO mode).