alias me="menv"

# Source dev.zsh first to make dev_alias_as function available
source ~/.menv/alias/dev/dev.sh

if command -v pyenv 1>/dev/null 2>&1; then
	eval "$(pyenv init -)"
fi

export SHELL_START_DIR="$(pwd)"

# Load all configuration files from ~/.menv/alias/ recursively (excluding dev.zsh which is already sourced)
setopt extended_glob glob_star_short
for config_file in ~/.menv/alias/**/*.sh~**/dev/dev.sh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done
