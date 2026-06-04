alias me="mev"
export SHELL_START_DIR="${SHELL_START_DIR:-$PWD}"

# dev_alias_as must be loaded before files that call it.
[[ -r "$HOME/.mev/alias/dev/dev.sh" ]] && source "$HOME/.mev/alias/dev/dev.sh"
[[ -r "$HOME/.mev/alias/dev/dev.zsh" ]] && source "$HOME/.mev/alias/dev/dev.zsh"

setopt null_glob

for config_file in "$HOME"/.mev/alias/**/*.(sh|zsh)(N); do
  [[ "$config_file" == "$HOME/.mev/alias/dev/dev.sh" ]] && continue
  [[ "$config_file" == "$HOME/.mev/alias/dev/dev.zsh" ]] && continue
  [[ -r "$config_file" ]] && source "$config_file"
done

if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init - zsh)"
fi

if command -v goenv >/dev/null 2>&1; then
  eval "$(goenv init - zsh)"
fi

if command -v fnm >/dev/null 2>&1; then
  eval "$(fnm env --use-on-cd --version-file-strategy=recursive --shell zsh)"
fi

if command -v brew >/dev/null 2>&1; then
  BREW_PREFIX="$(brew --prefix)"
  [[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
    source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
  [[ -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] &&
    source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi
