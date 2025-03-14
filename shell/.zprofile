# Apple Silicon 向けの Homebrew の設定
eval "$(/opt/homebrew/bin/brew shellenv)"

# Android SDK の環境変数
if [[ -z "$ANDROID_HOME" ]]; then
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
fi

if [[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/latest/bin:"* ]]; then
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"
fi

# Flutter のパスを設定
if [[ -d "/opt/homebrew/Caskroom/flutter" ]]; then
    FLUTTER_VERSION=$(ls /opt/homebrew/Caskroom/flutter | sort -rV | head -n 1)
    export PATH="/opt/homebrew/Caskroom/flutter/${FLUTTER_VERSION}/flutter/bin:$PATH"
fi

# SSH Agent Configuration
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check if ssh-agent is already running
   if ! pgrep -u "$USER" ssh-agent > /dev/null; then
       # Start ssh-agent
       eval "$(ssh-agent -s)"
   fi
fi

# Add SSH key if not already added
if ! ssh-add -l > /dev/null 2>&1; then
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
fi
