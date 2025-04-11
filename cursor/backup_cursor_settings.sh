#!/bin/bash

# Cursorの設定ディレクトリ
CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
ENVIRONMENT_CURSOR_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# バックアップ対象のファイル
FILES_TO_BACKUP=(
    "settings.json"
    "keybindings.json"
)

# 設定ファイルのバックアップ
echo "Backing up Cursor settings..."
for file in "${FILES_TO_BACKUP[@]}"; do
    if [ -f "$CURSOR_CONFIG_DIR/$file" ]; then
        echo "Backing up $file..."
        cp "$CURSOR_CONFIG_DIR/$file" "$ENVIRONMENT_CURSOR_DIR/"
    else
        echo "Warning: $file not found"
    fi
done

# 拡張機能のバックアップ
echo "Backing up installed extensions..."
# 現在インストールされている拡張機能のリストを取得
installed_extensions=$(cursor --list-extensions)

if [ $? -eq 0 ]; then
    # extensions.jsonを生成
    echo "{" > "$ENVIRONMENT_CURSOR_DIR/extensions.json"
    echo "    \"recommendations\": [" >> "$ENVIRONMENT_CURSOR_DIR/extensions.json"
    
    # 拡張機能IDを追加
    first=true
    while IFS= read -r extension; do
        if [ "$first" = true ]; then
            echo "        \"$extension\"" >> "$ENVIRONMENT_CURSOR_DIR/extensions.json"
            first=false
        else
            echo "        ,\"$extension\"" >> "$ENVIRONMENT_CURSOR_DIR/extensions.json"
        fi
    done <<< "$installed_extensions"
    
    echo "    ]" >> "$ENVIRONMENT_CURSOR_DIR/extensions.json"
    echo "}" >> "$ENVIRONMENT_CURSOR_DIR/extensions.json"
    
    echo "Successfully backed up $(echo "$installed_extensions" | wc -l | tr -d ' ') extensions to extensions.json"
else
    echo "Warning: Failed to get installed extensions list"
fi

echo "Cursor settings backup completed!" 