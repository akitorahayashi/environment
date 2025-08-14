#!/bin/bash

unset PYENV_VERSION

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

changed=false
 # 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: pyenv"
if ! command -v pyenv &> /dev/null; then
    brew install pyenv
    changed=true
fi

# pyenvを初期化して、以降のコマンドでpyenvのPythonが使われるようにする
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# 3.12系で最新の安定版Pythonのバージョンを取得
echo "[INFO] 3.12系の最新の安定版Pythonのバージョンを確認しています..."
LATEST_PYTHON_VERSION=$(pyenv install --list | grep -E "^\s*3\.12\.[0-9]+$" | sort -V | tail -n 1 | tr -d ' ')
if [ -z "$LATEST_PYTHON_VERSION" ]; then
    echo "[ERROR] 3.12系の最新の安定版Pythonのバージョンが取得できませんでした。"
    exit 1
fi
readonly PYTHON_VERSION="$LATEST_PYTHON_VERSION"
echo "[INFO] 3.12系の最新の安定版Pythonのバージョンは ${PYTHON_VERSION} です。"

# Python の最新の安定版がインストールされていなければインストール
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

# グローバルバージョンをPython の最新の安定版に設定
python_version_changed=false
if [ "$(pyenv global)" != "${PYTHON_VERSION}" ]; then
    echo "[CONFIG] pyenv global を ${PYTHON_VERSION} に設定します"
    pyenv global "${PYTHON_VERSION}"
    pyenv rehash
    changed=true
    python_version_changed=true
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
    changed=true
else
    echo "[INFO] pipx はすでにインストールされています"
fi

# Pythonバージョンが変更された場合、pipxツールをすべて再インストール
if [ "$python_version_changed" = true ] && command -v pipx &> /dev/null; then
    echo "[INFO] Pythonバージョンが変更されたため、pipxツールを再インストールします"
    if pipx list --short 2>/dev/null | grep -q .; then
        echo "[REINSTALL] pipxツールを新しいPythonバージョンで再インストール中..."
        pipx reinstall-all --python "$(pyenv which python)"
        changed=true
    else
        echo "[INFO] 再インストールするpipxツールがありません"
    fi
fi

# pipxで管理するツールをインストール
PIPX_TOOLS_FILE="$REPO_ROOT/config/python/pipx-tools.txt"
if [ -f "$PIPX_TOOLS_FILE" ]; then
    echo "[INFO] $PIPX_TOOLS_FILE からツールをインストールします"
    installed_tools_output=$(pipx list)

    while IFS= read -r tool_package_raw || [ -n "$tool_package_raw" ]; do
        # 行末コメントを除去し、前後空白をトリム
        tool_package="${tool_package_raw%%#*}"
        tool_package="$(echo "$tool_package" | xargs)"
        # 空行はスキップ
        if [[ -z "$tool_package" ]]; then
            continue
        fi

        # すでにインストールされているかチェック
        if echo "$installed_tools_output" | grep -q "package $tool_package "; then
            echo "[INFO] $tool_package はすでにインストールされています"
        else
            echo "[INSTALL] $tool_package"
            if ! pipx install "$tool_package" --python "$(pyenv which python)"; then
                echo "[ERROR] $tool_package のインストールに失敗しました" >&2
                exit 1
            fi
            echo "IDEMPOTENCY_VIOLATION" >&2
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

    while IFS= read -r tool_package_raw || [ -n "$tool_package_raw" ]; do
        # 行末コメントを除去し、前後空白をトリム
        tool_package="${tool_package_raw%%#*}"
        tool_package="$(echo "$tool_package" | xargs)"
        # 空行はスキップ
        if [[ -z "$tool_package" ]]; then
            continue
        fi

        # インストールされているかチェック
        if echo "$installed_tools_output_verify" | grep -q "package $tool_package "; then
            echo "[SUCCESS] $tool_package は正常にインストールされています"
        else
            echo "[ERROR] $tool_package がインストールされていません"
            exit 1
        fi
    done < "$PIPX_TOOLS_FILE"
else
    echo "[WARN] $PIPX_TOOLS_FILE が見つかりません"
fi

echo "[SUCCESS] Python環境の検証が完了しました"