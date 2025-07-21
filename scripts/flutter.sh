#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
SETUP_DIR="$SCRIPT_DIR"  # セットアップディレクトリを保存

# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: fvm"
if ! command -v fvm &> /dev/null; then
    brew tap leoafarias/fvm
    brew install leoafarias/fvm/fvm
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "[Start] fvm を使用してFlutter SDK のセットアップを開始します"

changed=false
# 安定版 Flutter SDK のインストール (fvm install は冪等)
echo "[INFO] 安定版 Flutter SDK をインストールします..."

# 既にインストール済みかチェック
fvm_stable_path="$HOME/fvm/versions/stable"
was_already_installed=false
if [ -d "$fvm_stable_path" ]; then
    was_already_installed=true
fi

if fvm install stable; then
    # 新規インストールの場合のみフラグを設定
    if [ "$was_already_installed" = false ]; then
        changed=true
        echo "[SUCCESS] Flutter SDK (stable) を新規インストールしました。"
    else
        echo "[SUCCESS] Flutter SDK (stable) は既にインストール済みです。"
    fi
else
    echo "[ERROR] fvm install stable に失敗しました。"
    exit 1
fi

# 現在のグローバル設定が stable か確認
fvm_default_link="$HOME/fvm/default"
is_global_already_stable=false
if [ -L "$fvm_default_link" ] && [ "$(readlink "$fvm_default_link")" == "$fvm_stable_path" ]; then
    is_global_already_stable=true
fi

# グローバル設定がまだ stable でなければ設定
if [ "$is_global_already_stable" = true ]; then
    echo "[SUCCESS] fvm global は既に stable に設定されています。スキップします。"
else
    echo "[INFO] fvm global stable を設定します..."
    if fvm global stable; then
        echo "[SUCCESS] fvm global stable の設定が完了しました。"
        changed=true
    else
        echo "[ERROR] fvm global stable の設定に失敗しました。"
        exit 1
    fi
fi

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# FVM管理下のFlutterを使うため、PATHを更新
export PATH="$HOME/fvm/default/bin:$PATH"
echo "[INFO] 現在のシェルセッションのPATHにfvmのパスを追加しました。"

# flutter コマンド存在確認 (fvm管理下のパスで)
if ! command -v flutter >/dev/null 2>&1; then
    echo "[ERROR] Flutter コマンド (fvm管理下) が見つかりません"
    exit 1
fi

# Flutterのパスを確認 (fvm管理下のパス)
FLUTTER_PATH=$(which flutter)
echo "[INFO] Flutter PATH: $FLUTTER_PATH"

# パスが正しいか確認（FVM管理下のパスを確認）
expected_fvm_path="$HOME/fvm/default/bin/flutter"
if [[ "$FLUTTER_PATH" != "$expected_fvm_path" ]]; then
    echo "[ERROR] Flutter (fvm) が期待するパスにありません"
    echo "[INFO] 現在のパス: $FLUTTER_PATH"
    echo "[INFO] 期待するパス: $expected_fvm_path"
    exit 1
else
    echo "[SUCCESS] Flutter (fvm) のパスが正しく設定されています"
fi

# Flutter環境の簡易確認 (バージョン表示)
echo "==== Start: Flutter環境を確認中... ===="
# IS_CI チェックを削除し、常に flutter --version を実行
if flutter --version > /dev/null 2>&1; then
    echo "[INFO] Flutter のバージョン確認を実行しました"
else
    # 失敗した場合はエラーとして処理し、終了する
    echo "[ERROR] flutter --version の実行に失敗しました。"
    echo "[INFO] 詳細な診断には 'flutter doctor' を実行してみてください。"
    exit 1
fi

echo "[SUCCESS] Flutter環境のセットアップが完了しました"

# --- 検証フェーズ ---
echo "==== Start: Flutter環境を検証中... ===="
verification_failed=false

# インストール確認
echo "[OK] Flutter"

# パス確認
FLUTTER_PATH=$(which flutter)
echo "[INFO] Flutter PATH: $FLUTTER_PATH"

# FVM管理下のパスを期待する
expected_fvm_path="$HOME/fvm/default/bin/flutter"
if [[ "$FLUTTER_PATH" != "$expected_fvm_path" ]]; then
    echo "[ERROR] Flutterのパスが想定と異なります"
    echo "[ERROR] 期待: $expected_fvm_path"
    echo "[ERROR] 実際: $FLUTTER_PATH"
    verification_failed=true
else
    echo "[SUCCESS] Flutterのパスが正しく設定されています"
fi

# 環境チェック
echo "[INFO] Flutter環境チェック (flutter --version) を実行中..."
if ! flutter --version > /dev/null 2>&1; then
    echo "[ERROR] flutter --version の実行に失敗しました"
    verification_failed=true
fi
echo "[SUCCESS] Flutterコマンドが正常に動作しています"

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Flutter環境の検証に失敗しました"
    exit 1
else
    echo "[SUCCESS] Flutter環境の検証が完了しました"
fi