#!/bin/bash

set -euo pipefail

# 使用するJDKのバージョンを定数として定義
readonly JDK_VERSION="21"

# main sets up the Java development environment by ensuring Temurin JDK version 21 is installed, applies environment changes, and verifies the installation.
main() {
    echo "==== Start: Java環境のセットアップを開始します..."

    # temurin@<バージョン>がインストールされていなければインストール
    if ! brew list --cask "temurin@${JDK_VERSION}" > /dev/null 2>&1; then
        echo "[INSTALL] temurin@${JDK_VERSION}"
        local brew_install_cmd=("brew" "install" "--cask")
        if [ "${CI:-false}" = "true" ]; then
            brew_install_cmd+=("--no-quarantine")
        fi

        if ! "${brew_install_cmd[@]}" "temurin@${JDK_VERSION}"; then
            echo "[ERROR] temurin@${JDK_VERSION} のインストールに失敗しました"
            exit 1
        fi
        echo "IDEMPOTENCY_VIOLATION" >&2
    else
        echo "[INFO] temurin@${JDK_VERSION} はすでにインストールされています"
    fi

    echo "[SUCCESS] Java環境のセットアップが完了しました"


    # .zprofileをsourceして環境変数を反映
    if [ -f "$HOME/.zprofile" ]; then
        source "$HOME/.zprofile"
    fi

    verify_java_setup
}

verify_java_setup() {
    echo "==== Start: Java環境を検証中..."

    # temurinがインストールされているか確認
    if ! brew list --cask "temurin@${JDK_VERSION}" > /dev/null 2>&1; then
        echo "[ERROR] temurin@${JDK_VERSION} がインストールされていません"
        exit 1
    else
        echo "[SUCCESS] temurin@${JDK_VERSION} はインストールされています"
    fi

    # JAVA_HOMEが設定されているか確認
    if [ -z "${JAVA_HOME:-}" ]; then
        echo "[ERROR] JAVA_HOME が設定されていません"
        exit 1
    else
        echo "[SUCCESS] JAVA_HOME は設定されています: $JAVA_HOME"
    fi

    # javaコマンドが実行できるか確認
    if ! java -version > /dev/null 2>&1; then
        echo "[ERROR] java コマンドが実行できません"
        exit 1
    else
        echo "[SUCCESS] java コマンドは実行可能です: $(java -version 2>&1 | head -n 1)"
    fi

    echo "[SUCCESS] Java環境の検証が完了しました"
}

main "$@"