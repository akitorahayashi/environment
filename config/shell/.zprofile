# Apple Silicon 用 Homebrew の初期化
eval "$(/opt/homebrew/bin/brew shellenv)"

# ユーザーローカルの bin ディレクトリを PATH に追加
if [ -d "$HOME/bin" ] && [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
    export PATH="$HOME/bin:$PATH"
fi

# FVM 用 PATH 設定
if [ -d "$HOME/fvm/default/bin" ] && [[ ":$PATH:" != *":$HOME/fvm/default/bin:"* ]]; then
    export PATH="$HOME/fvm/default/bin:$PATH"
fi

# Android SDK 環境変数
if [[ -z "$ANDROID_HOME" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/latest/bin:"* ]]; then
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

# SSH Agent 設定
if [ -z "$SSH_AUTH_SOCK" ]; then
   # ssh-agent が実行されていない場合に起動
   if ! pgrep -u "$USER" ssh-agent > /dev/null; then
       eval "$(ssh-agent -s)"
   fi
fi

# SSH キーを ssh-agent に追加 (まだ追加されていない場合)
if ! ssh-add -l > /dev/null 2>&1; then
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi

# rbenv 初期化
if command -v rbenv 1>/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

# nvm 初期化
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
  . "$(brew --prefix nvm)/nvm.sh" --no-use # スクリプト読み込み時に use しない
fi

# JAVA_HOME 設定
if ! command -v /usr/libexec/java_home >/dev/null 2>&1; then
    echo "Error: /usr/libexec/java_home is not installed." >&2
    exit 1
fi
export JAVA_HOME="$(/usr/libexec/java_home -v "21")"
