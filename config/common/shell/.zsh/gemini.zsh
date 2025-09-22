alias gm="gemini"

# Function to generate gemini aliases automatically
gm_alias() {
    local model suffix prefix="gm"

    while getopts "m:t:a:" opt; do
        case $opt in
            m) model="$OPTARG" ;;
            t) suffix="$OPTARG" ;;
            a) prefix="$OPTARG" ;;
            *) echo "Invalid option: -$opt"; return 1 ;;
        esac
    done

    if [[ -z "$model" || -z "$suffix" ]]; then
        echo "Usage: gm_alias -m <model> -t <suffix> [-a <prefix>]"
        return 1
    fi

    # Generate base alias if prefix is specified
    if [[ -n "$prefix" ]]; then
        alias ${prefix}="gemini"
    fi

    # Generate aliases
    alias ${prefix}-${suffix}="gemini -m $model"
    alias ${prefix}-${suffix}-y="gemini -m $model -y"
    alias ${prefix}-${suffix}-p="gemini -m $model -p"
    alias ${prefix}-${suffix}-a-p="gemini -a -m $model -p"
}

# Highest performance
gm_alias -m "gemini-2.5-pro" -t "pr"

# Cost-performance balance priority
gm_alias -m "gemini-2.5-flash" -t "fl"

# Lightweight 
gm_alias -m "gemini-2.5-flash-lite" -t "lt" -a "gm"

# When you want to generate images or have image-attached conversations
gm_alias -m "gemini-2.5-flash-image-preview" -t "i"
# gemini command options
# -p, --prompt: Specify a prompt. Appended to input on stdin (if any). Used in non-interactive mode.
# -a, --all-files: Include ALL files in context?
# -y, --yolo: Automatically accept all actions (aka YOLO mode).