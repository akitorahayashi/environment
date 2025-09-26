# Source dev.zsh first to make dev_alias_as function available
source ~/.zsh/dev/dev.zsh

# Load all configuration files from ~/.zsh/ recursively (excluding dev.zsh which is already sourced)
setopt extended_glob glob_star_short
for config_file in ~/.zsh/**/*.zsh~**/dev/dev.zsh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done