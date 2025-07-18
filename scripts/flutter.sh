#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"
SETUP_DIR="$SCRIPT_DIR"  # セットアップディレクトリを保存

# 依存関係をインストール
install_dependencies() {
    echo "[INFO] 依存関係をチェック・インストールします: fvm"
    if ! command -v fvm &> /dev/null; then
        brew tap leoafarias/fvm
        brew install leoafarias/fvm/fvm
        echo "IDEMPOTENCY_VIOLATION" >&2
    fi
}

main() {
    install_dependencies
    echo "[Start] fvm を使用してFlutter SDK のセットアップを開始します"

    local changed=false
    # 安定版 Flutter SDK のインストール (fvm install は冪等)
    echo "[INFO] 安定版 Flutter SDK をインストールします..."
    
    # 既にインストール済みかチェック
    local fvm_stable_path="$HOME/fvm/versions/stable"
    local was_already_installed=false
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
    local fvm_default_link="$HOME/fvm/default"
    local is_global_already_stable=false
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
    local expected_fvm_path="$HOME/fvm/default/bin/flutter"
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

    verify_flutter_setup
}

verify_flutter_setup() {
    echo "==== Start: Flutter環境を検証中... ===="
    local verification_failed=false
    
    # インストール確認
    if ! verify_flutter_installation; then
        return 1
    fi
    
    # パス確認
    verify_flutter_path || verification_failed=true
    
    # 環境チェック (常に verify_flutter_environment を実行)
    verify_flutter_environment || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] Flutter環境の検証に失敗しました"
        return 1
    else
        echo "[SUCCESS] Flutter環境の検証が完了しました"
        return 0
    fi
}

verify_flutter_installation() {
    echo "[OK] Flutter"
    return 0
}

verify_flutter_path() {
    FLUTTER_PATH=$(which flutter)
    echo "[INFO] Flutter PATH: $FLUTTER_PATH"
    
    # FVM管理下のパスを期待する
    local expected_fvm_path="$HOME/fvm/default/bin/flutter"
    if [[ "$FLUTTER_PATH" != "$expected_fvm_path" ]]; then
        echo "[ERROR] Flutterのパスが想定と異なります"
        echo "[ERROR] 期待: $expected_fvm_path"
        echo "[ERROR] 実際: $FLUTTER_PATH"
        return 1
    else
        echo "[SUCCESS] Flutterのパスが正しく設定されています"
        return 0
    fi
}

verify_flutter_environment() {
    # IS_CI チェックを削除し、常に verify_flutter_full_environment を呼び出す
    verify_flutter_full_environment # 引数なしに変更
    return $?
}

verify_flutter_full_environment() {
    echo "[INFO] Flutter環境チェック (flutter --version) を実行中..."
    if ! flutter --version > /dev/null 2>&1; then
        echo "[ERROR] flutter --version の実行に失敗しました"
        return 1
    fi
    echo "[SUCCESS] Flutterコマンドが正常に動作しています"
    
    return 0
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi