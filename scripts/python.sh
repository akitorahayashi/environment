#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するPythonのバージョンを定数として定義
readonly PYTHON_VERSION="3.12.4"

# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: pyenv, pyenv-virtualenv"
if ! command -v pyenv &> /dev/null; then
    brew install pyenv
    echo "IDEMPOTENCY_VIOLATION" >&2
fi
if ! brew list pyenv-virtualenv &> /dev/null; then
    brew install pyenv-virtualenv
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
    if ! pyenv install "${PYTHON_VERSION}"; then
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
    # PATH へ pipx の bin ディレクトリを追加
    pipx ensurepath
    # ensurepath は次回シェルから有効になるため、当該シェルでも即座に反映
    export PATH="$HOME/.local/bin:$PATH"
    echo "IDEMPOTENCY_VIOLATION" >&2
else
    echo "[INFO] pipx はすでにインストールされています"
fi

# Poetryのインストール
if ! command -v poetry &> /dev/null; then
    echo "[INSTALL] poetry"
    pipx install poetry
    echo "IDEMPOTENCY_VIOLATION" >&2
else
    echo "[INFO] poetry はすでにインストールされています"
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

if ! type pyenv | grep -q 'function'; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
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

# poetryのチェック
if ! command -v poetry >/dev/null 2>&1; then
    echo "[ERROR] poetryコマンドが見つかりません"
    exit 1
fi
echo "[SUCCESS] poetry: $(poetry --version)"


echo "[SUCCESS] Python環境の検証が完了しました"
