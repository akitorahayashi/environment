alias g="git"
alias gi="git"

# Auto-generated git aliases from git config
generate_git_aliases() {
    # Get all git aliases and convert them to zsh aliases with 'g' prefix
    git config --get-regexp '^alias\.' | sed 's/^alias\.\([^ ]*\) .*/alias g\1="git \1"/'
}

# Generate and source git aliases
eval "$(generate_git_aliases)"