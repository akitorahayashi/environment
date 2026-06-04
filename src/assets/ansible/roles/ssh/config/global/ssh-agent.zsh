# shellcheck disable=SC2148
# Automatic startup and reuse of SSH Agent
SSH_AGENT_PID_FILE="$HOME/.ssh/ssh-agent.pid"
SSH_AUTH_SOCK_FILE="$HOME/.ssh/ssh-agent.sock"

# Respect externally provided agents, including forwarded SSH agent sockets.
if [[ -n "${SSH_AUTH_SOCK:-}" && -S "$SSH_AUTH_SOCK" ]]; then
  # shellcheck disable=SC2317
  return 0 2>/dev/null || exit 0
fi

_ssh_agent_process_matches() {
  local pid="$1"
  local process_name process_cmdline

  case "$pid" in
    '' | *[!0-9]*) return 1 ;;
  esac

  if [[ -r "/proc/$pid/comm" ]]; then
    IFS= read -r process_name <"/proc/$pid/comm" || return 1
    [[ "$process_name" == "ssh-agent" ]]
    return
  fi

  if [[ -r "/proc/$pid/cmdline" ]]; then
    process_cmdline="$(tr '\0' ' ' <"/proc/$pid/cmdline" 2>/dev/null)" || return 1
    [[ "$process_cmdline" == *ssh-agent* ]]
    return
  fi

  process_name="$(ps -p "$pid" -o comm= 2>/dev/null)" || return 1
  process_name="${process_name#"${process_name%%[![:space:]]*}"}"
  process_name="${process_name%"${process_name##*[![:space:]]}"}"
  process_name="${process_name##*/}"
  [[ "$process_name" == "ssh-agent" ]]
}

_ssh_agent_cached_pid=""
_ssh_agent_cached_sock=""

if [[ -r "$SSH_AGENT_PID_FILE" && -r "$SSH_AUTH_SOCK_FILE" ]]; then
  IFS= read -r _ssh_agent_cached_pid <"$SSH_AGENT_PID_FILE"
  IFS= read -r _ssh_agent_cached_sock <"$SSH_AUTH_SOCK_FILE"

  if [[ -S "$_ssh_agent_cached_sock" ]] &&
    kill -0 "$_ssh_agent_cached_pid" 2>/dev/null &&
    _ssh_agent_process_matches "$_ssh_agent_cached_pid"; then
    export SSH_AGENT_PID="$_ssh_agent_cached_pid"
    export SSH_AUTH_SOCK="$_ssh_agent_cached_sock"
  else
    rm -f "$SSH_AGENT_PID_FILE" "$SSH_AUTH_SOCK_FILE"
  fi
fi

# If SSH agent is not running, start a new one.
if [[ -z "${SSH_AGENT_PID:-}" ]] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
  eval "$(ssh-agent -s)"
  echo "$SSH_AGENT_PID" >"$SSH_AGENT_PID_FILE"
  echo "$SSH_AUTH_SOCK" >"$SSH_AUTH_SOCK_FILE"
fi

unset _ssh_agent_cached_pid _ssh_agent_cached_sock
unfunction _ssh_agent_process_matches
