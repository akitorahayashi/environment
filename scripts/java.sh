#!/bin/bash

set -euo pipefail

# 使用するJDKのバージョンを定数として定義
readonly JDK_VERSION="24.0.1"

main() {
    echo "==== Start: Java環境のセットアップを開始します..."

    # temurin@<バージョン>がインストールされていなければインストール
    if ! brew list --cask "temurin@${JDK_VERSION}" > /dev/null 2>&1; then
        echo "[INSTALL] temurin@${JDK_VERSION}"
        if ! brew install --cask "temurin@${JDK_VERSION}"; then
            echo "[ERROR] temurin@${JDK_VERSION} のインストールに失敗しました"
            exit 1
        fi
        echo "INSTALL_PERFORMED"
    else
        echo "[INFO] temurin@${JDK_VERSION} はすでにインストールされています"
    fi

    echo "[SUCCESS] Java環境のセットアップが完了しました"

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

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
