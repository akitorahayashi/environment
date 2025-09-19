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