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
alias pt-r-p-mp="poetry run python manage.py"
alias pt-u="poetry update"
alias pt-ls="poetry list"
alias pt-lock="poetry lock"
alias pt-e="poetry export -f requirements.txt --output requirements.txt --without-hashes"
alias pt-v="poetry env list"
alias pt-v-rm="poetry env remove"

# venv
alias act='source ./.venv/bin/activate'
alias deact='deactivate'

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

# django
alias dj-st-proj="poetry run django-admin startproject"
alias dj-st-a="poetry run python manage.py startapp"
alias dj-s="poetry run python manage.py runserver"
alias dj-mk-m="poetry run python manage.py makemigrations"
alias dj-m="poetry run python manage.py migrate"
alias dj-sh="poetry run python manage.py shell"
alias dj-chk="poetry run python manage.py check"
alias dj-mchk="poetry run python manage.py makemigrations --check"
alias dj-csu="poetry run python manage.py createsuperuser"
alias dj-tst="poetry run python manage.py test"

# black
alias bl="black ."
alias bl-chk="black --check ."

# ruff
alias rf="ruff check ."

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
  for cmd in pandoc lualatex; do
    command -v $cmd >/dev/null 2>&1 || { echo "Error: $cmd is not installed." >&2; return 1; }
  done
  [[ $# -ne 2 || ! -f $1 ]] && { echo "Usage: md2pdf <input.md> <output.pdf> (input file must exist)" >&2; return 2; }
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
