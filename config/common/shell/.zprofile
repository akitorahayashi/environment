# Apple Silicon 用 Homebrew の初期化
eval "$(/opt/homebrew/bin/brew shellenv)"

# poppler のパス
export PATH="/opt/homebrew/opt/poppler/bin:$PATH"

# pipx/poetry 用のパス
export PATH="$HOME/.local/bin:$PATH"

# Android SDK 環境変数
if [[ -z "$ANDROID_HOME" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/latest/bin:"* ]]; then
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

# rbenv の初期化
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# pyenv の初期化
if command -v pyenv 1>/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init --path)"
fi

# ollama models のパス設定
export OLLAMA_MODELS="$HOME/.ollama/models"

# nvm の初期化
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh"
fi

# JAVA_HOME の設定
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

# Android SDK (追加PATHのみ)
if [ -n "$ANDROID_HOME" ]; then
  if [ -d "$ANDROID_HOME/emulator" ] && [[ ":$PATH:" != *":$ANDROID_HOME/emulator:"* ]]; then
    export PATH="$PATH:$ANDROID_HOME/emulator"
  fi
  if [ -d "$ANDROID_HOME/platform-tools" ] && [[ ":$PATH:" != *":$ANDROID_HOME/platform-tools:"* ]]; then
    export PATH="$PATH:$ANDROID_HOME/platform-tools"
  fi
fi

# FVM 用 PATH 設定
if [ -d "$HOME/fvm/default/bin" ] && [[ ":$PATH:" != *":$HOME/fvm/default/bin:"* ]]; then
    export PATH="$HOME/fvm/default/bin:$PATH"
fi