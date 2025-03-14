#!/bin/bash

# Cursorの設定ディレクトリ
CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
ENVIRONMENT_CURSOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# リストア対象のファイル
FILES_TO_RESTORE=(
    "settings.json"
    "keybindings.json"
    "extensions.json"
)

# Cursorがインストールされているか確認
if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
    echo "Cursor is not installed. Please install Cursor first."
    exit 1
fi

# 設定ファイルのリストア
echo "Restoring Cursor settings..."
for file in "${FILES_TO_RESTORE[@]}"; do
    if [ -f "$ENVIRONMENT_CURSOR_DIR/$file" ]; then
        echo "Restoring $file..."
        cp "$ENVIRONMENT_CURSOR_DIR/$file" "$CURSOR_CONFIG_DIR/"
    else
        echo "Warning: $file not found in backup"
    fi
done

echo "Cursor settings restored successfully!" 