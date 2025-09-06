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
alias deact='deactivate'
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
alias pv-ls="pyenv versions"
alias pv-s="pyenv shell"
alias pv-g="pyenv global"
alias pv-l="pyenv local"

# pytest
alias pts="pytest"

# django
alias dj-stpj="django-admin startproject"
alias dj-sta="django-admin startapp"
alias dj-mp-sta="python manage.py startapp"
alias dj-s="python manage.py runserver"
alias dj-mk-m="python manage.py makemigrations"
alias dj-m="python manage.py migrate"
alias dj-sh="python manage.py shell"
alias dj-chk="python manage.py check"
alias dj-chkm="python manage.py makemigrations --check"
alias dj-csu="python manage.py createsuperuser"
alias dj-ts="python manage.py test"

# black
alias bl="black ."
alias bl-chk="black --check ."

# ruff
alias rf="ruff check . --fix"
alias rf-chk="ruff check ."

# streamlit
alias st="streamlit"
alias st-r="streamlit run"

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
alias bd-e="bundle exec"
alias bd-f="bundle exec fastlane"
alias bd-i="bundle install"

# Node.js
alias np="npm"
alias np-i="npm install"
alias np-r="npm run"

# Docker
alias dc="docker"
alias dc-b="docker build"
alias dc-r="docker run"
alias dc-i="docker images"
alias dc-ps="docker ps"
alias dc-st="docker stop"
alias dc-rm="docker rm"
alias dc-c-r="docker-compose run"

# brew
alias br="brew"
alias br-ls="brew list"
alias br-i="brew install"
alias br-i-c="brew install --cask"
alias br-ui="brew uninstall"
alias br-ui-c="brew uninstall --cask"
alias br-s-ls="brew services list"

# postgresql
alias pst-st="brew services start postgresql"
alias pst-stp="brew services stop postgresql"
alias pst-rs="brew services restart postgresql"
alias pst-r="psql"

# redis
alias rd-st="brew services start redis"
alias rd-stp="brew services stop redis"
alias rd-rs="brew services restart redis"
alias rd-cli="redis-cli"

# Mint
alias mi-r="mint run"

# Makefile
alias mk="make"
alias mk-h="make help"
alias mk-s="make setup"
alias mk-f="make format"
alias mk-l="make lint"
alias mk-fl="make format lint"
alias mk-r="make run"
alias mk-t="make test"
alias mk-ut="make unit-test"
alias mk-uit="make ui-test"
alias mk-et="make e2e-test"
alias mk-dt="make db-test"
alias mk-st="make sdk-test"
alias mk-pt="make perf-test"
alias mk-it="make intg-test"

# xcode
alias xc="xed"

# vscode
alias co="code"

# AppleScript
alias as="osascript"

# Gemini
alias gmn="gemini"

# Claude
alias cld="claude"

# git
alias g="git"
alias gi="git"
alias gb="git branch"
alias gp="git pull"
alias gps="git push"
alias gps-u-o="git push -u origin"
alias gps-f-l="git push --force-with-lease"
alias gps-o="git push origin"
alias gc="git add .;git commit -m"
alias gic="git add .;git commit -m"
alias gl="git lg"
alias glg="git lg"

# open
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

# Utility
alias al="alias"
alias sc="source"
alias ct="cat"
alias tc="touch"
alias rel="source ~/.zshrc"
alias cl="clear"
alias gip="ipconfig getifaddr"

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


ssh-gk() {
    local type="$1"
    local host="$2"

    if [ -z "$type" ] || [ -z "$host" ]; then
      echo "Error: Both type and host arguments are required." >&2
      echo "Usage: ssh-gk <type> <host>" >&2
      echo "Allowed types: rsa, dsa, ecdsa, ed25519" >&2
      return 1
    fi

    case "$type" in
      rsa|dsa|ecdsa|ed25519)
        ;;
      *)
        echo "Error: Invalid key type '$type'." >&2
        echo "Usage: ssh-gk <type> <host>" >&2
        echo "Allowed types: rsa, dsa, ecdsa, ed25519" >&2
        return 1
      ;; 
    esac

    local keyfile_path="$HOME/.ssh/id_${type}_${host}"
    local keyfile_config="~/.ssh/id_${type}_${host}"
    local keyfile_pub="${keyfile_path}.pub"

    ssh-keygen -t "$type" -f "$keyfile_path" -C "$host"

   # Add to SSH config
   {
     echo ""
     echo "Host $host"
     echo "  HostName $host"
     echo "  User git"
     echo "  IdentityFile $keyfile_config"
     echo "  IdentitiesOnly yes"
   } >> ~/.ssh/config

   echo "SSH key generated and config added for $host to ~/.ssh/config"
   echo "Public key:"
   cat "${keyfile_path}.pub"
}

ssh-ls() {
  awk '/^Host / && $2 != "*" {print $2}' ~/.ssh/config
}

ssh-rm() {
  local host="$1"
  if [ -z "$host" ]; then
    echo "Error: host argument is required." >&2
    echo "Usage: ssh-rm <host>" >&2
    return 1
  fi

  # Find IdentityFile path from config
  local keyfile
  keyfile=$(awk -v host="$host" ' \
    $1 == "Host" && $2 == host { in_block=1 } \
    in_block && /IdentityFile/ { print $2; exit } \
    in_block && /^Host / && NR > 1 { exit } \
  ' ~/.ssh/config)

  if [ -n "$keyfile" ]; then
    local keyfile_path="${keyfile/#\~/$HOME}"
    if [ -f "$keyfile_path" ]; then
      rm "$keyfile_path" && echo "Removed key file from config: $keyfile_path"
      if [ -f "${keyfile_path}.pub" ]; then
        rm "${keyfile_path}.pub" && echo "Removed public key file from config: ${keyfile_path}.pub"
      fi
    fi
  else
    echo "Info: No IdentityFile found for host '$host' in ssh config. Checking for default files."
  fi

  # Fallback: Remove conventionally-named key files
  local key_pattern_glob="$HOME/.ssh/id_*_${host}*"
  local files_to_delete=( ${~key_pattern_glob} )
  if (( ${#files_to_delete[@]} )); then
    rm "${files_to_delete[@]}" && echo "Removed conventionally-named key files: ${files_to_delete[@]}"
  fi

  # Remove config block from ~/.ssh/config
  awk -v host="$host" ' \
    /^Host / {
      if ($2 == host) {
        in_block_to_delete=1
      } else {
        in_block_to_delete=0
      }
    }
    !in_block_to_delete
  ' ~/.ssh/config > ~/.ssh/config.tmp && mv ~/.ssh/config.tmp ~/.ssh/config && chmod 600 ~/.ssh/config

  echo "Removed config block for '$host' from ~/.ssh/config."
}

# ssh agent
ssha-ls() {
  ssh-add -l 2>/dev/null | awk '/^[0-9]/{print $3}'
}

ssha-a() {
  local host="$1"
  local key=$(awk -v host="$host" ' 
    $1 == "Host" && $2 == host { in_block=1; next }
    in_block && /^Host / { exit }
    in_block && /IdentityFile/ { print $2; exit }
  ' ~/.ssh/config)
  if [ -n "$key" ]; then
    # ~ を $HOME に展開
    local key_expanded="${key/#\~/$HOME}"
    ssh-add "$key_expanded"
  else
    echo "No IdentityFile found for host: $host" >&2
  fi
}

ssha-rm() {
  local host="$1"
  local key=$(awk -v host="$host" ' 
    $1 == "Host" && $2 == host { in_block=1; next }
    in_block && /^Host / { exit }
    in_block && /IdentityFile/ { print $2; exit }
  ' ~/.ssh/config)
  if [ -n "$key" ]; then
    # ~ を $HOME に展開
    local key_expanded="${key/#\~/$HOME}"
    ssh-add -d "$key_expanded"
  else
    echo "No IdentityFile found for host: $host" >&2
  fi
}
