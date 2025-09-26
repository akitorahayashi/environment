if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# uv
alias u="uv"
alias u-ini="uv init"
u-v() {
  if [[ -f ".python-version" ]]; then
    pyver=$(<.python-version)
  else
    echo ".python-version not found. Exiting."
    return 1
  fi

  if ! pyenv versions --bare | grep -qx "$pyver"; then
    echo "Python $pyver is not installed. Installing..."
    pyenv install "$pyver"
  fi

  if [[ $# -eq 1 ]]; then
    uv venv "$1" --python "$(pyenv which python)"
  else
    uv venv --python "$(pyenv which python)"
  fi
}
alias u-a="uv add"
alias u-s="uv sync"
alias u-s-e="uv sync --extra"
alias u-s-nd="uv sync --no-dev"
alias u-s-og="uv sync --only-group"
alias u-lk="uv lock"
alias u-rv="rm-vev;u-v;u-s"
alias u-r="uv run"
alias u-e="uv export --format requirements.txt > requirements.txt"

# uv tool
alias ut-r="uv tool run"

# uvx
alias ux="uvx"
alias ux-c="uvx cowsay -t"
alias ux-srn-st='uvx --from git+https://github.com/oraios/serena serena start-mcp-server'
alias ux-srn-idx='uvx --from git+https://github.com/oraios/serena serena project index "$(pwd)"'

# venv
act() {
  if [[ $# -eq 1 ]]; then
    source "./$1/bin/activate"
  else
    source "./.venv/bin/activate"
  fi
}
alias dct='deactivate'
rm-vev() {
  if [[ $# -eq 1 ]]; then
    rm -rf "./$1"
  else
    rm -rf "./.venv"
  fi
}

# pipx
alias px="pipx"
alias px-ls="pipx list"
alias px-i="pipx install"
alias px-ui="pipx uninstall"
alias px-r="pipx run"

# pyenv
alias pv="pyenv"
alias pv-i="pyenv install"
alias pv-ui="pyenv uninstall"
alias pv-ls="pyenv versions"
alias pv-s="pyenv shell"
alias pv-g="pyenv global"
alias pv-l="pyenv local"

# python project cleanup
py-cln() {
  echo "🧹 Cleaning up project..."
  find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
  rm -rf .venv
  rm -rf .pytest_cache
  rm -rf .ruff_cache
  echo "✅ Cleanup completed"
}