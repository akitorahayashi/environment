# config/common/shell/.zsh/ssh.zsh

ssh-gk() {
    local type="$1"
    local host="$2"
    if [ -z "$type" ] || [ -z "$host" ]; then
      echo "Usage: ssh-gk <type> <host>" >&2; return 1
    fi
    # type/host のバリデーション
    case "$type" in
      ed25519|rsa|ecdsa) ;;
      *) echo "Error: Unsupported key type '$type' (allowed: ed25519|rsa|ecdsa)." >&2; return 1 ;;
    esac
    if ! [[ "$host" =~ ^[A-Za-z0-9._-]+$ ]]; then
      echo "Error: Invalid host '$host' (allowed: [A-Za-z0-9._-]+)." >&2; return 1
    fi

    mkdir -p "$HOME/.ssh/conf.d"

    local keyfile_path="$HOME/.ssh/id_${type}_${host}"
    local host_config_file="$HOME/.ssh/conf.d/${host}.conf"

    if [ -f "$host_config_file" ]; then
        echo "Error: Config for host '$host' already exists." >&2; return 1
    fi

    if [ -e "$keyfile_path" ] || [ -e "${keyfile_path}.pub" ]; then
      echo "Error: Key files already exist: '$keyfile_path'(.pub)." >&2; return 1
    fi
    ssh-keygen -q -t "$type" -f "$keyfile_path" -C "$host" -N ''

    cat > "$host_config_file" << EOF
Host $host
  HostName $host
  User git
  IdentityFile ~/.ssh/id_${type}_${host}
  IdentitiesOnly yes
EOF
    chmod 600 "$host_config_file"
    echo "✅ SSH key and config for '$host' created."
    echo "🔑 Public key:"
    cat "${keyfile_path}.pub"
}

ssh-ls() {
  \ls -1 ~/.ssh/conf.d/*.conf 2>/dev/null | sed 's/\.conf$//' | awk -F/ '{print $NF}'
}

ssh-rm() {
  local host="$1"
  if [ -z "$host" ]; then echo "Usage: ssh-rm <host>" >&2; return 1; fi

  local host_config_file="$HOME/.ssh/conf.d/${host}.conf"
  if [ ! -f "$host_config_file" ]; then
    echo "Error: Config for host '$host' not found." >&2; return 1
  fi

  local keyfile=$(awk '/IdentityFile/ {print $2}' "$host_config_file")
  if [ -n "$keyfile" ]; then
    rm -f "${keyfile/#\~/$HOME}" "${keyfile/#\~/$HOME}.pub"
    echo "🗑️ Removed key files for $host."
  fi

  rm "$host_config_file"
  echo "🗑️ Removed config file for '$host'."
}

ssha-ls() {
  ssh-add -l 2>/dev/null | awk '/^[0-9]/{print $3}'
}
