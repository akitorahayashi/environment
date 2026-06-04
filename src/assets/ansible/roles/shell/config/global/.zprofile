_path_prepend() {
  [[ -d "$1" ]] || return
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

_path_append() {
  [[ -d "$1" ]] || return
  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$PATH:$1" ;;
  esac
}

# Homebrew initialization
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

_path_prepend "$HOME/.local/bin"
_path_prepend "$HOME/.cargo/bin"
_path_prepend "$HOME/.local/pipx/venvs/mlx-hub/bin"
_path_prepend "$HOME/.menv/venvs/mlx-lm/bin"
_path_prepend "/opt/homebrew/opt/poppler/bin"
_path_prepend "$PNPM_HOME"

_path_prepend "$ANDROID_HOME/cmdline-tools/latest/bin"
_path_prepend "$ANDROID_HOME/tools/bin"
_path_prepend "$ANDROID_HOME/platform-tools"
_path_append "$ANDROID_HOME/emulator"

export GOENV_ROOT="${GOENV_ROOT:-$HOME/.goenv}"
_path_prepend "$GOENV_ROOT/bin"
_path_prepend "$HOME/go/bin"

# SSH agent initialization
if [[ -r "$HOME/.ssh/ssh-agent.zsh" ]]; then
  source "$HOME/.ssh/ssh-agent.zsh"
fi
