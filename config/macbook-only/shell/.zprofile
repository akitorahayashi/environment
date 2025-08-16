# Apple Silicon 用 Homebrew の初期化
eval "$(/opt/homebrew/bin/brew shellenv)"

# poppler のパス
export PATH="/opt/homebrew/opt/poppler/bin:$PATH"

# ユーザーローカルの bin ディレクトリ
if [ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

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
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# ollama models のパス設定
export OLLAMA_MODELS="$HOME/.ollama/models"

# nvm の初期化
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh"
fi

# JAVA_HOME の設定
if ! command -v /usr/libexec/java_home >/dev/null 2>&1; then
    echo "Error: /usr/libexec/java_home is not installed." >&2
    exit 1
fi
export JAVA_HOME="$(/usr/libexec/java_home -v "21")"

# Android SDK
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools

# FVM 用 PATH 設定
if [ -d "$HOME/fvm/default/bin" ] && [[ ":$PATH:" != *":$HOME/fvm/default/bin:"* ]]; then
    export PATH="$HOME/fvm/default/bin:$PATH"
fi