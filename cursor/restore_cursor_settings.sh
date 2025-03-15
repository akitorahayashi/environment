#!/bin/bash

# 環境変数の設定
ENVIRONMENT_DIR="$HOME/environment"
if [[ -n "$GITHUB_WORKSPACE" ]]; then
    ENVIRONMENT_DIR="$GITHUB_WORKSPACE"
fi

# Cursorの設定ディレクトリ
CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
ENVIRONMENT_CURSOR_DIR="$ENVIRONMENT_DIR/cursor"

# 設定ディレクトリが存在することを確認
if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
    mkdir -p "$CURSOR_CONFIG_DIR"
fi

# 設定ファイルのリストア
echo "Restoring Cursor settings..."
FILES_TO_RESTORE=("settings.json" "keybindings.json" "extensions.json")
for file in "${FILES_TO_RESTORE[@]}"; do
    if [ -f "$ENVIRONMENT_CURSOR_DIR/$file" ]; then
        echo "Restoring $file..."
        cp "$ENVIRONMENT_CURSOR_DIR/$file" "$CURSOR_CONFIG_DIR/"
    else
        echo "Warning: $file not found in backup"
    fi
done

echo "Cursor settings restored successfully!" 