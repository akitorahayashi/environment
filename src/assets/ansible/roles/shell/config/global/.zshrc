alias me="mev"

# Source dev.zsh first to make dev_alias_as function available
source ~/.mev/alias/dev/dev.sh

if command -v fnm >/dev/null 2>&1; then
	eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi

if command -v frum >/dev/null 2>&1; then
	eval "$(frum init)"
fi

export SHELL_START_DIR="$(pwd)"


# Load all configuration files from ~/.mev/alias/ recursively (excluding dev.zsh which is already sourced)
setopt extended_glob glob_star_short null_glob
for config_file in ~/.mev/alias/**/*.sh~**/dev/dev.sh; do
    if [ -r "$config_file" ]; then
        source "$config_file"
    fi
done

if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  [ -r "${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ] && source "${BREW_PREFIX}/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [ -r "${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ] && source "${BREW_PREFIX}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Added by Antigravity
export PATH="/Users/akitorahayashi/.antigravity/antigravity/bin:$PATH"
