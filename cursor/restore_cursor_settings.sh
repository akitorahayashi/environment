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

# 拡張機能のインストール
if [ -f "$ENVIRONMENT_CURSOR_DIR/extensions.json" ]; then
    echo "Installing recommended extensions..."
    
    # Cursorコマンドラインツールのパス
    CURSOR_CLI="/Applications/Cursor.app/Contents/Resources/app/bin/cursor"
    
    # Cursorコマンドラインツールが存在するか確認
    if [ -f "$CURSOR_CLI" ]; then
        # インストール済み拡張機能のリストを取得
        echo "Checking installed extensions..."
        INSTALLED_EXTENSIONS=$("$CURSOR_CLI" --list-extensions | tr '[:upper:]' '[:lower:]')
        
        # extensions.jsonから拡張機能IDを抽出してインストール
        EXTENSIONS=$(grep -o '"[^"]*"' "$ENVIRONMENT_CURSOR_DIR/extensions.json" | grep -v "recommendations" | tr -d '"')
        
        for extension in $EXTENSIONS; do
            # 拡張機能IDを小文字に変換して比較
            EXTENSION_LOWER=$(echo "$extension" | tr '[:upper:]' '[:lower:]')
            
            if echo "$INSTALLED_EXTENSIONS" | grep -q "$EXTENSION_LOWER"; then
                echo "Extension already installed: $extension ✅"
            else
                echo "Installing extension: $extension"
                "$CURSOR_CLI" --install-extension "$extension" || echo "Failed to install $extension ❌"
            fi
        done
        
        echo "Extensions installation completed!"
    else
        echo "Error: Cursor CLI not found at $CURSOR_CLI"
        exit 1
    fi
fi

echo "Cursor settings restored successfully!" 