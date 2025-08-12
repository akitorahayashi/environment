# Python
alias poet-n="poetry new"
alias poet-ini="poetry init"
alias poet-i="poetry install"
alias poet-a="poetry add"
alias poet-rm="poetry remove"
alias poet-r="poetry run python"
alias poet-u="poetry update"
alias poet-ls="poetry list"
alias poet-lock="poetry lock"
alias poet-e="poetry export -f requirements.txt --output requirements.txt --without-hashes"
alias poet-env="poetry env list"
alias poet-env-d="poetry env remove"

alias pl="pip list"
alias pi="pip install"
alias pu="python -m pip install --upgrade pip"
alias pui="pip uninstall"
alias pir="pip install -r requirements.txt"
alias pif="pip freeze > requirements.txt"

# Ollama
alias ol="ollama"
alias ol-ls="ollama list"
alias ol-pl="ollama pull"
alias ol-r="ollama run"
alias ol-s="ollama serve"
alias ol-sp="ollama stop"
alias ol-c="ollama create"
alias ol-d="ollama delete"

# Aider
aid-set() {
  export OLLAMA_API_BASE="$1"
}
aid-lch() {
  aider --model "ollama/$1" --no-auto-commit --no-gitignore
}

# Ruby
alias be="bundle exec"
alias be-f="bundle exec fastlane"
alias bi="bundle install"

# Node.js
alias ni="npm install"
alias nr="npm run"

# Mint
alias mr="mint run"

# Makefile
alias mk="make"

# AppleScript
alias as="osascript"

# Utility
alias op="open"
alias op-f="open ."
alias op-s="open -a 'System Preferences'"
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
  pandoc "$1" -o "$2" --pdf-engine=lualatex \
    -V documentclass=ltjarticle \
    -V mainfont="Hiragino Mincho ProN" \
    -V sansfont="Hiragino Sans" \
    -V monofont="Hiragino Kaku Gothic ProN" \
    -V geometry:a4paper \
    -V geometry:margin=2.5cm
}
