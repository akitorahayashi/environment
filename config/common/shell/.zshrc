if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Poetry
alias pt="poetry"
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
alias pt-lk="poetry lock"
alias pt-e="poetry export -f requirements.txt --output requirements.txt --without-hashes"
alias pt-v="poetry env list"
alias pt-v-rm="poetry env remove"

# venv
alias act='source ./.venv/bin/activate'
alias deact='deactivate'

# pip
alias pi="pip"

# pipx
alias px="pipx"
alias px-ls="pipx list"
alias px-i="pipx install"
alias px-ui="pipx uninstall"
alias px-r="pipx run"

# pytest
alias pt-r-ts="poetry run pytest"

# django
alias dj-stpj="poetry run django-admin startproject"
alias dj-sta="poetry run django-admin startapp"
alias dj-mp-sta="poetry run python manage.py startapp"
alias dj-s="poetry run python manage.py runserver"
alias dj-mk-m="poetry run python manage.py makemigrations"
alias dj-m="poetry run python manage.py migrate"
alias dj-sh="poetry run python manage.py shell"
alias dj-chk="poetry run python manage.py check"
alias dj-chkm="poetry run python manage.py makemigrations --check"
alias dj-csu="poetry run python manage.py createsuperuser"
alias dj-ts="poetry run python manage.py test"

# black
alias pt-bl="poetry run black ."
alias pt-bl-chk="poetry run black --check ."

# ruff
alias pt-rf="poetry run ruff check . --fix"
alias pt-rf-chk="poetry run ruff check ."

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

# xcode
alias xc="xed"

# vscode
alias cde="code"

# AppleScript
alias as="osascript"

# git
alias g="git"
alias gi="git"
alias gb="git branch"
alias gp="git pull"
alias gps="git push"
alias gc="git add .;git commit -m"
alias gic="git add .;git commit -m"

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
alias ct="cat"
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
  local key=$(grep -A 10 "Host $host" ~/.ssh/config | grep IdentityFile | awk '{print $2}')
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
  local key=$(grep -A 10 "Host $host" ~/.ssh/config | grep IdentityFile | awk '{print $2}')
  if [ -n "$key" ]; then
    # ~ を $HOME に展開
    local key_expanded="${key/#\~/$HOME}"
    ssh-add -d "$key_expanded"
  else
    echo "No IdentityFile found for host: $host" >&2
  fi
}
