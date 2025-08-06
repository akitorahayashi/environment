# Python
alias poet-init="poetry init"
alias poet-i="poetry install"
alias poet-a="poetry add"
alias poet-rm="poetry remove"
alias poet-r="poetry run python"
alias poet-u="poetry update"
alias poet-ls="poetry list"
alias poet-lock="poetry lock"
alias poet-env="poetry env list"
alias poet-env-d="poetry env remove"

alias pl="pip list"
alias pi="pip install"
alias pu="python -m pip install --upgrade pip"
alias pui="pip uninstall"
alias pir="pip install -r requirements.txt"
alias pif="pip freeze > requirements-lock.txt"

# Ollama
alias ol="ollama"
alias ol-ls="ollama list"
alias ol-pl="ollama pull"
alias ol-r="ollama run"
alias ol-s="ollama serve"
alias ol-c="ollama create"
alias ol-d="ollama delete"

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

# Utility
alias op="open"
alias op-a="open -a 'Android Studio'"
alias op-c="open -a 'Google Chrome'"

md2pdf() {
  pandoc "$1" -o "$2" --pdf-engine=lualatex \
    -V documentclass=ltjarticle \
    -V mainfont="Hiragino Mincho ProN" \
    -V sansfont="Hiragino Sans" \
    -V monofont="Hiragino Kaku Gothic ProN" \
    -V geometry:a4paper \
    -V geometry:margin=2.5cm
}