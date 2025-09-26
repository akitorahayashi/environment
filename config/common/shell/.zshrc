# Source dev.zsh first to make dev_alias_as function available
source ~/.zsh/dev/dev.zsh

# Load all configuration files from ~/.zsh/ recursively
setopt glob_star_short
for config_file in ~/.zsh/**/*.zsh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done