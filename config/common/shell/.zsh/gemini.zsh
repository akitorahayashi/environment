alias gmn="gemini"

# Highest performance
alias gmn-pro="gemini -m gemini-2.5-pro"

# Cost-performance balance priority
alias gmn-fl="gemini -m gemini-2.5-flash"

# Want to use cheaply, fast, and in large quantities
alias gmn-lt="gemini -m gemini-2.5-flash-lite"
alias gmn-lt-p="gemini -m gemini-2.5-flash-lite -p"
alias gmn-lt-a-p="gemini -a -m gemini-2.5-flash-lite -p"

# When you want to generate images or have image-attached conversations
alias gmn-i="gemini -m gemini-2.5-flash-image-preview"
alias gmn-lv="gemini -m gemini-2.5-flash-image-live-preview"

# gemini command options
# -p, --prompt: Specify a prompt. Appended to input on stdin (if any). Used in non-interactive mode.
# -a, --all-files: Include ALL files in context?
# -y, --yolo: Automatically accept all actions (aka YOLO mode).