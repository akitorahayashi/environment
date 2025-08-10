#!/bin/bash

set -euo pipefail

unset PYENV_VERSION

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するPythonのバージョンを定数として定義
readonly PYTHON_VERSION="3.12.4"

 # 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: pyenv"
if ! command -v pyenv &> /dev/null; then
    brew install pyenv
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "==== Start: Python環境のセットアップを開始します..."


# pyenvを初期化して、以降のコマンドでpyenvのPythonが使われるようにする
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

changed=false
# Python 3.12.4がインストールされていなければインストール
if ! pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
    echo "[INSTALL] Python ${PYTHON_VERSION}"
    if ! pyenv install --skip-existing "${PYTHON_VERSION}"; then
        echo "[ERROR] Python ${PYTHON_VERSION} のインストールに失敗しました"
        exit 1
    fi
    changed=true
else
    echo "[INFO] Python ${PYTHON_VERSION} はすでにインストールされています"
fi

# グローバルバージョンを3.12.4に設定
if [ "$(pyenv global)" != "${PYTHON_VERSION}" ]; then
    echo "[CONFIG] pyenv global を ${PYTHON_VERSION} に設定します"
    pyenv global "${PYTHON_VERSION}"
    pyenv rehash
    changed=true
else
    echo "[INFO] pyenv global はすでに ${PYTHON_VERSION} に設定されています"
fi

# pipxのインストール
if ! command -v pipx &> /dev/null; then
    echo "[INSTALL] pipx"
    python -m pip install --user pipx
    # ensurepath は次回シェルから有効になるため、当該シェルでも即座に反映
    export PATH="$HOME/.local/bin:$PATH"
    hash -r  # コマンドキャッシュをクリア
    # PATH へ pipx の bin ディレクトリを追加
    pipx ensurepath
    echo "IDEMPOTENCY_VIOLATION" >&2
else
    echo "[INFO] pipx はすでにインストールされています"
fi

# pipxで管理するツールをインストール
PIPX_TOOLS_FILE="$REPO_ROOT/config/python/pipx-tools.txt"
if [ -f "$PIPX_TOOLS_FILE" ]; then
    echo "[INFO] $PIPX_TOOLS_FILE からツールをインストールします"
    installed_tools_output=$(pipx list)

    while IFS= read -r tool_package || [ -n "$tool_package" ]; do
        # 空行やコメント行をスキップ
        if [[ -z "$tool_package" || "$tool_package" == \#* ]]; then
            continue
        fi

        # すでにインストールされているかチェック
        if echo "$installed_tools_output" | grep -q "package $tool_package "; then
            echo "[INFO] $tool_package はすでにインストールされています"
        else
            echo "[INSTALL] $tool_package"
            if pipx install "$tool_package" --python "$(pyenv which python)"; then
                echo "IDEMPOTENCY_VIOLATION" >&2
            else
                echo "[ERROR] $tool_package のインストールに失敗しました"
            fi
        fi
    done < "$PIPX_TOOLS_FILE"
else
    echo "[WARN] $PIPX_TOOLS_FILE が見つかりません"
fi


# 最終的な環境情報を表示
echo "[INFO] Python環境: $(python -V)"
echo "[SUCCESS] Python環境のセットアップが完了しました"

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "==== Start: Python環境を検証中..."
# pyenvチェック
if ! command -v pyenv >/dev/null 2>&1; then
    echo "[ERROR] pyenvコマンドが見つかりません"
    exit 1
fi



echo "[SUCCESS] pyenv: $(pyenv --version)"

# Pythonバージョンチェック
if [ "$(pyenv version-name)" != "${PYTHON_VERSION}" ]; then
    echo "[ERROR] Pythonのバージョンが${PYTHON_VERSION}ではありません"
    exit 1
else
    echo "[SUCCESS] Python: $(python -V)"
fi

# pipxのチェック
if ! command -v pipx >/dev/null 2>&1; then
    echo "[ERROR] pipxコマンドが見つかりません"
    exit 1
fi
echo "[SUCCESS] pipx: $(pipx --version)"

# pipxで管理するツールを検証
if [ -f "$PIPX_TOOLS_FILE" ]; then
    echo "[INFO] $PIPX_TOOLS_FILE に記載のツールを検証します"
    # 検証のたびに最新のリストを取得
    installed_tools_output_verify=$(pipx list)

    while IFS= read -r tool_package || [ -n "$tool_package" ]; do
        # 空行やコメント行をスキップ
        if [[ -z "$tool_package" || "$tool_package" == \#* ]]; then
            continue
        fi

        # pipxでインストールされているか確認
        if ! echo "$installed_tools_output_verify" | grep -q "package $tool_package "; then
             echo "[ERROR] $tool_package は pipx でインストールされていません"
             exit 1
        fi

        # パッケージ名からコマンド名を取得する
        # デフォルトはパッケージ名と同じ
        command_name="$tool_package"
        # 例外: aider-chatパッケージのコマンドはaider
        if [ "$tool_package" = "aider-chat" ]; then
            command_name="aider"
        fi

        if ! command -v "$command_name" >/dev/null 2>&1; then
            echo "[ERROR] $command_name コマンドが見つかりません（$tool_package パッケージ）"
            exit 1
        fi

        # バージョン表示を試みる。失敗してもエラーにはしない。
        version_info="$($command_name --version 2>/dev/null || echo "version not found")"
        echo "[SUCCESS] $tool_package (command: $command_name): $version_info"
    done < "$PIPX_TOOLS_FILE"
else
    echo "[WARN] $PIPX_TOOLS_FILE が見つかりません。ツールの検証をスキップします。"
fi


echo "[SUCCESS] Python環境の検証が完了しました"