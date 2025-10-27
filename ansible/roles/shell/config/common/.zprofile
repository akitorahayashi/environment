# Homebrew initialization for Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Disable Homebrew auto-update
export HOMEBREW_NO_AUTO_UPDATE=1

# Path for menv helper scripts
export PATH="{{ repo_root_path }}/ansible/scripts/shell:$PATH"

# Path for poppler
export PATH="/opt/homebrew/opt/poppler/bin:$PATH"

# Path for cli tools
export PATH="$HOME/.local/bin:$PATH"

# Path for pipx tools
export PATH="$HOME/.local/pipx/venvs/mlx-hub/bin:$PATH"

# Path for mlx-lm tools under menv
export PATH="$HOME/.menv/venvs/mlx-lm/bin:$PATH"

# Android SDK environment variables
if [[ -z "$ANDROID_HOME" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/latest/bin:"* ]]; then
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

# rbenv initialization
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# pyenv initialization
if command -v pyenv 1>/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# Path setting for ollama models
export OLLAMA_MODELS="$HOME/.ollama/models"

# export OLLAMA_API_BASE for aider
export OLLAMA_API_BASE="http://localhost:11434"

# Set practical timeout for aider (5 minutes max)
export AIDER_TIMEOUT=300

# nvm initialization
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh"
fi

# pnpm initialization
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# JAVA_HOME setup
if [ -x /usr/libexec/java_home ]; then
  JAVA_21=$(/usr/libexec/java_home -v 21 2>/dev/null)
  if [ -n "$JAVA_21" ]; then
    export JAVA_HOME="$JAVA_21"
  else
    echo "Warning: Java 21 not found. Skipping JAVA_HOME setup." >&2
  fi
else
  echo "Warning: /usr/libexec/java_home not available. Skipping JAVA_HOME setup." >&2
fi

# Android SDK (additional PATH only)
if [ -n "$ANDROID_HOME" ]; then
  if [ -d "$ANDROID_HOME/emulator" ] && [[ ":$PATH:" != *":$ANDROID_HOME/emulator:"* ]]; then
    export PATH="$PATH:$ANDROID_HOME/emulator"
  fi
  if [ -d "$ANDROID_HOME/platform-tools" ] && [[ ":$PATH:" != *":$ANDROID_HOME/platform-tools:"* ]]; then
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
  fi
fi

# PATH setting for FVM
if [ -d "$HOME/fvm/default/bin" ] && [[ ":$PATH:" != *":$HOME/fvm/default/bin:"* ]]; then
    export PATH="$HOME/fvm/default/bin:$PATH"
fi

# Path for Rust tools
if [ -d "$HOME/.cargo/bin" ] && [[ ":$PATH:" != *":$HOME/.cargo/bin:"* ]]; then
    export PATH="$HOME/.cargo/bin:$PATH"
fi

# Automatic startup and reuse of SSH Agent
SSH_AGENT_PID_FILE="$HOME/.ssh/ssh-agent.pid"
SSH_AUTH_SOCK_FILE="$HOME/.ssh/ssh-agent.sock"

# Check existing SSH agent process
if [ -f "$SSH_AGENT_PID_FILE" ]; then
    SSH_AGENT_PID=$(cat "$SSH_AGENT_PID_FILE")
    if kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
        # If the process is alive, set environment variables
        export SSH_AGENT_PID
        export SSH_AUTH_SOCK=$(cat "$SSH_AUTH_SOCK_FILE")
    else
        # If the process is dead, remove files
        rm -f "$SSH_AGENT_PID_FILE" "$SSH_AUTH_SOCK_FILE"
    fi
fi

# If SSH agent is not running, start a new one
if [ -z "$SSH_AGENT_PID" ] || ! kill -0 "$SSH_AGENT_PID" 2>/dev/null; then
    eval "$(ssh-agent -s)"
    echo "$SSH_AGENT_PID" > "$SSH_AGENT_PID_FILE"
    echo "$SSH_AUTH_SOCK" > "$SSH_AUTH_SOCK_FILE"
fi
