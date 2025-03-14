#!/bin/bash

# ==========================
# Xcode 設定の復元方法
# ==========================
# 1. このスクリプトを実行すると、`environment/xcode/` のバックアップデータが Xcode に復元されます。
# 2. 以下のディレクトリの設定が復元されます:
#    - CodeSnippets
#    - FontAndColorThemes
#    - IDETemplateMacros.plist
#    - KeyBindings
#
# 使用例:
# ```
# bash ~/environment/restore_xcode_settings.sh
# ```

# Xcode の設定ディレクトリ
XCODE_USERDATA_DIR="$HOME/Library/Developer/Xcode/UserData"
ENVIRONMENT_XCODE_DIR="$HOME/environment/xcode"

# Xcode がインストールされているか確認
if [ ! -d "$XCODE_USERDATA_DIR" ]; then
    echo "❌ Xcode がインストールされていません。先に Xcode をインストールしてください。"
    exit 1
fi

# 必要なディレクトリを作成
mkdir -p "$XCODE_USERDATA_DIR/CodeSnippets"
mkdir -p "$XCODE_USERDATA_DIR/FontAndColorThemes"
mkdir -p "$XCODE_USERDATA_DIR/KeyBindings"
mkdir -p "$ENVIRONMENT_XCODE_DIR/CodeSnippets"
mkdir -p "$ENVIRONMENT_XCODE_DIR/FontAndColorThemes"
mkdir -p "$ENVIRONMENT_XCODE_DIR/KeyBindings"

echo "🔄 Xcode 設定を復元中..."

# CodeSnippets の復元
echo "📝 CodeSnippets を復元中..."
if [ -n "$(ls -A $ENVIRONMENT_XCODE_DIR/CodeSnippets 2>/dev/null)" ]; then
    rsync -av --delete "$ENVIRONMENT_XCODE_DIR/CodeSnippets/" "$XCODE_USERDATA_DIR/CodeSnippets/"
else
    echo "ℹ️ CodeSnippets のバックアップが見つかりません。デフォルト設定を使用します。"
fi

# FontAndColorThemes の復元
echo "🎨 FontAndColorThemes を復元中..."
if [ -n "$(ls -A $ENVIRONMENT_XCODE_DIR/FontAndColorThemes 2>/dev/null)" ]; then
    rsync -av --delete "$ENVIRONMENT_XCODE_DIR/FontAndColorThemes/" "$XCODE_USERDATA_DIR/FontAndColorThemes/"
else
    echo "ℹ️ FontAndColorThemes のバックアップが見つかりません。デフォルト設定を使用します。"
fi

# IDETemplateMacros.plist の復元
echo "📄 IDETemplateMacros.plist を確認中..."
if [[ -f "$ENVIRONMENT_XCODE_DIR/IDETemplateMacros.plist" ]]; then
    echo "📄 IDETemplateMacros.plist を復元中..."
    cp "$ENVIRONMENT_XCODE_DIR/IDETemplateMacros.plist" "$XCODE_USERDATA_DIR/IDETemplateMacros.plist"
    echo "✅ IDETemplateMacros.plist を復元しました"
else
    echo "ℹ️ IDETemplateMacros.plist のバックアップが見つかりません。デフォルト設定を使用します。"
fi

# KeyBindings の復元
echo "⌨️ KeyBindings を復元中..."
if [ -n "$(ls -A $ENVIRONMENT_XCODE_DIR/KeyBindings 2>/dev/null)" ]; then
    rsync -av --delete "$ENVIRONMENT_XCODE_DIR/KeyBindings/" "$XCODE_USERDATA_DIR/KeyBindings/"
else
    echo "ℹ️ KeyBindings のバックアップが見つかりません。デフォルト設定を使用します。"
fi

echo "🎉 Xcode 設定の復元が完了しました！"
