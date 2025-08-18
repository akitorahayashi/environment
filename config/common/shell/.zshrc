if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Poetry
alias pt-n="poetry new"
alias pt-ini="poetry init --no-interaction"
alias pt-i="poetry install"
alias pt-a="poetry add"
alias pt-rm="poetry remove"
alias pt-r="poetry run"
alias pt-r-p="poetry run python"
alias pt-r-p-m="poetry run python -m"
alias pt-r-p-mp="poetry run python manager.py"
alias pt-u="poetry update"
alias pt-ls="poetry list"
alias pt-lock="poetry lock"
alias pt-e="poetry export -f requirements.txt --output requirements.txt --without-hashes"
alias pt-env="poetry env list"
alias pt-env-d="poetry env remove"

# pipx
alias px="pipx"
alias px-ls="pipx list"
alias px-i="pipx install"
alias px-ui="pipx uninstall"
alias px-r="pipx run"

# pip
alias pl="pip list"
alias pi="pip install"
alias pi-up="python -m pip install --upgrade pip"
alias pi-ui="pip uninstall"
alias pi-r-rq="pip install -r requirements.txt"
alias pi-f="pip freeze > requirements.txt"

# Ollama
alias ol="ollama"
alias ol-ls="ollama list"
alias ol-pl="ollama pull"
alias ol-r="ollama run"
alias ol-s="ollama serve"
alias ol-sp="ollama stop"
alias ol-c="ollama create"
alias ol-d="ollama delete"

# Ruby
alias be="bundle exec"
alias be-f="bundle exec fastlane"
alias bi="bundle install"

# Node.js
alias ni="npm install"
alias nr="npm run"

# Docker
alias dc="docker"
alias dc-b="docker build"
alias dc-r="docker run"
alias dc-i="docker images"
alias dc-ps="docker ps"
alias dc-st="docker stop"
alias dc-rm="docker rm"

# Mint
alias mr="mint run"

# Makefile
alias mk="make"

# AppleScript
alias as="osascript"

# Utility
alias rel="source ~/.zshrc"
alias gi="git"
alias cl="clear"
alias op="open"
alias op-f="open ."
alias op-s="open -b com.apple.systempreferences"
alias op-st="open -a 'Stickies'"
alias op-o="open -a 'Obsidian'"
alias op-as="open -a 'Android Studio'"
alias op-a="open -a 'Automator'"
alias op-sc="open -a 'Script Editor'"
alias op-t="open -na Terminal"
alias op-c="open -a 'Google Chrome'"
alias op-cg="open -a 'Google Chrome' 'https://github.com/akitorahayashi'"
alias op-cj="open -a 'Google Chrome' 'https://jules.google.com/task'"

md2pdf() {
  if ! command -v pandoc >/dev/null 2>&1; then
    echo "Error: pandoc is not installed." >&2
    return 1
  fi
  if ! command -v lualatex >/dev/null 2>&1; then
    echo "Error: lualatex (TeX Live) is not installed." >&2
    return 1
  fi
  # 引数チェック
  if [ $# -ne 2 ]; then
    echo "Usage: md2pdf <input.md> <output.pdf>" >&2
    return 2
  fi
  if [ ! -f "$1" ]; then
    echo "Error: input file not found: $1" >&2
    return 2
  fi
  pandoc "$1" -o "$2" --pdf-engine=lualatex \
    -V documentclass=ltjarticle \
    -V mainfont="Hiragino Mincho ProN" \
    -V sansfont="Hiragino Sans" \
    -V monofont="Hiragino Kaku Gothic ProN" \
    -V geometry:a4paper \
    -V geometry:margin=2.5cm
}

# Aider
ai-st() {
  export OLLAMA_API_BASE="$1"
}
ai-ch() {
  local model="${1:?usage: ai-lch <model> [aider-args...]}"
  shift
  aider --model "ollama/$model" --no-auto-commit --no-gitignore "$@"
}
