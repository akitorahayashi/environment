#!/bin/bash

# ==========================
# Xcode 設定のバックアップ方法
# ==========================
# 1. このスクリプトを実行すると、Xcode の設定が `environment/xcode/` に保存されます。
# 2. 以下のディレクトリの設定がバックアップされます:
#    - CodeSnippets
#    - FontAndColorThemes
#    - IDETemplateMacros.plist
#    - KeyBindings

# Xcode の設定ディレクトリ
XCODE_USERDATA_DIR="$HOME/Library/Developer/Xcode/UserData"
ENVIRONMENT_XCODE_DIR="$HOME/environment/xcode"

# バックアップディレクトリの作成
mkdir -p "$ENVIRONMENT_XCODE_DIR/CodeSnippets"
mkdir -p "$ENVIRONMENT_XCODE_DIR/FontAndColorThemes"
mkdir -p "$ENVIRONMENT_XCODE_DIR/KeyBindings"

echo "🔄 Xcode 設定を environment にバックアップ中..."

# CodeSnippets のバックアップ
echo "📝 CodeSnippets をバックアップ中..."
if [ -d "$XCODE_USERDATA_DIR/CodeSnippets" ]; then
    rsync -av --delete "$XCODE_USERDATA_DIR/CodeSnippets/" "$ENVIRONMENT_XCODE_DIR/CodeSnippets/"
else
    echo "⚠ CodeSnippets ディレクトリが見つかりません"
fi

# FontAndColorThemes のバックアップ
echo "🎨 FontAndColorThemes をバックアップ中..."
if [ -d "$XCODE_USERDATA_DIR/FontAndColorThemes" ]; then
    rsync -av --delete "$XCODE_USERDATA_DIR/FontAndColorThemes/" "$ENVIRONMENT_XCODE_DIR/FontAndColorThemes/"
else
    echo "⚠ FontAndColorThemes ディレクトリが見つかりません"
fi

# IDETemplateMacros.plist のバックアップ
if [[ -f "$XCODE_USERDATA_DIR/IDETemplateMacros.plist" ]]; then
    echo "📄 IDETemplateMacros.plist をバックアップ中..."
    cp "$XCODE_USERDATA_DIR/IDETemplateMacros.plist" "$ENVIRONMENT_XCODE_DIR/IDETemplateMacros.plist"
else
    echo "⚠ IDETemplateMacros.plist が見つかりません"
fi

# KeyBindings のバックアップ
echo "⌨️ KeyBindings をバックアップ中..."
if [ -d "$XCODE_USERDATA_DIR/KeyBindings" ]; then
    rsync -av --delete "$XCODE_USERDATA_DIR/KeyBindings/" "$ENVIRONMENT_XCODE_DIR/KeyBindings/"
else
    echo "KeyBindings ディレクトリが見つかりません"
fi

echo "🎉 Xcode 設定のバックアップが完了しました！"
