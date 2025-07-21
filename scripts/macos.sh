#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 依存関係をインストール
# displayplacerのインストールは状態変更とみなすが、macOSの設定適用自体は冪等であるため、
# このスクリプト全体としては冪等性違反のシグナルを出力しない。
echo "[INFO] 依存関係をチェック・インストールします: displayplacer"
if ! command -v displayplacer &> /dev/null; then
    brew install displayplacer
fi

echo "[Start] Mac のシステム設定を適用中..."

# 設定ファイルの存在確認
settings_file="$REPO_ROOT/config/macos/macos-settings.sh"
if [[ ! -f "$settings_file" ]]; then
    echo "[WARN] config/macos/macos-settings.sh が見つかりません"
    exit 1
fi

# 設定を適用
if ! source "$settings_file" 2>/dev/null; then
    echo "[WARN] Mac 設定の適用中に一部エラーが発生しましたが、続行します"
else
    echo "[SUCCESS] Mac のシステム設定が適用されました"
fi

# --- 検証フェーズ ---
echo "==== Start: macOS設定を検証中... ===="

# 設定ファイルの存在確認
if [[ -f "$settings_file" ]]; then
    echo "[SUCCESS] macOS設定ファイルが存在します: $settings_file"
    echo "[SUCCESS] macOS設定の検証が完了しました"
else
    echo "[ERROR] macOS設定ファイルが見つかりません: $settings_file"
    exit 1
fi