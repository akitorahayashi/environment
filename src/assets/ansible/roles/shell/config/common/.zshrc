alias me="mev"

# Source dev.zsh first to make dev_alias_as function available
source ~/.mev/alias/dev/dev.sh

if command -v pyenv 1>/dev/null 2>&1; then
	eval "$(pyenv init -)"
fi

export SHELL_START_DIR="$(pwd)"

# Load all configuration files from ~/.mev/alias/ recursively (excluding dev.zsh which is already sourced)
setopt extended_glob glob_star_short null_glob
for config_file in ~/.mev/alias/**/*.sh~**/dev/dev.sh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done

# Added by Antigravity
export PATH="/Users/akitorahayashi/.antigravity/antigravity/bin:$PATH"
