#!/bin/bash

set -euo pipefail

# 使用するJDKのバージョンを定数として定義
readonly JDK_CASK="temurin"
readonly JDK_VERSION="24.0.1"

main() {
    echo "==== Start: Java環境のセットアップを開始します..."

    # temurinがインストールされていなければインストール
    if ! brew list --cask ${JDK_CASK} > /dev/null 2>&1; then
        echo "[INSTALL] ${JDK_CASK}"
        if ! brew install --cask ${JDK_CASK}; then
            echo "[ERROR] ${JDK_CASK} のインストールに失敗しました"
            exit 1
        fi
        echo "INSTALL_PERFORMED"
    else
        echo "[INFO] ${JDK_CASK} はすでにインストールされています"
    fi

    echo "[SUCCESS] Java環境のセットアップが完了しました"

    verify_java_setup
}

verify_java_setup() {
    echo "==== Start: Java環境を検証中..."

    # temurinがインストールされているか確認
    if ! brew list --cask ${JDK_CASK} > /dev/null 2>&1; then
        echo "[ERROR] ${JDK_CASK} がインストールされていません"
        exit 1
    else
        echo "[SUCCESS] ${JDK_CASK} はインストールされています"
    fi

    # JAVA_HOMEが設定されているか確認
    if [ -z "$JAVA_HOME" ]; then
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
