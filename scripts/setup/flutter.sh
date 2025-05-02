#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SETUP_DIR="$SCRIPT_DIR"  # セットアップディレクトリを保存

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Flutter のセットアップ
setup_flutter() {
    log_start "Flutter SDK のセットアップを開始します (fvm)..."

    # fvm コマンドの存在確認
    if ! command_exists fvm; then
        handle_error "fvm コマンドが見つかりません。Brewfileを確認してください。"
        return 1
    fi

    # 安定版 Flutter SDK のインストール (fvm install は冪等)
    log_info "fvm を使用して安定版 Flutter SDK をインストールします..."
    if fvm install stable; then
        log_success "Flutter SDK (stable) のインストール/確認が完了しました。"
    else
        handle_error "fvm install stable に失敗しました。"
        return 1
    fi

    # 現在のグローバル設定が stable か確認
    local fvm_default_link="$HOME/fvm/default"
    local fvm_stable_path="$HOME/fvm/versions/stable"
    local is_global_already_stable=false
    if [ -L "$fvm_default_link" ] && [ "$(readlink "$fvm_default_link")" == "$fvm_stable_path" ]; then
        is_global_already_stable=true
    fi

    # グローバル設定がまだ stable でなければ設定
    if [ "$is_global_already_stable" = true ]; then
        log_success "fvm global は既に stable に設定されています。スキップします。"
    else
        log_info "fvm global stable を設定します..."
        if fvm global stable; then
            log_success "fvm global stable の設定が完了しました。"
        else
            handle_error "fvm global stable の設定に失敗しました。"
            return 1
        fi
    fi

    # FVM管理下のFlutterを使うため、PATHを更新
    export PATH="$HOME/fvm/default/bin:$PATH"
    log_info "現在のシェルセッションのPATHにfvmのパスを追加しました。"

    # flutter コマンド存在確認 (fvm管理下のパスで)
    if ! command_exists flutter; then
        handle_error "Flutter コマンド (fvm管理下) が見つかりません"
        return 1
    fi

    # Flutterのパスを確認 (fvm管理下のパス)
    FLUTTER_PATH=$(which flutter)
    log_info "Flutter PATH (fvm): $FLUTTER_PATH"

    # パスが正しいか確認（FVM管理下のパスを確認）
    local expected_fvm_path="$HOME/fvm/default/bin/flutter"
    if [[ "$FLUTTER_PATH" != "$expected_fvm_path" ]]; then
        log_error "Flutter (fvm) が期待するパスにありません"
        log_info "現在のパス: $FLUTTER_PATH"
        log_info "期待するパス: $expected_fvm_path"
        handle_error "Flutter (fvm) のパスが正しくありません"
        return 1
    else
        log_success "Flutter (fvm) のパスが正しく設定されています"
    fi

    # Flutter環境の簡易確認 (バージョン表示)
    log_start "Flutter環境を確認中..."
    # IS_CI チェックを削除し、常に flutter --version を実行
    if flutter --version > /dev/null 2>&1; then
        log_info "Flutter のバージョン確認を実行しました"
    else
        # 失敗した場合はエラーとして処理し、終了する
        handle_error "flutter --version の実行に失敗しました。Flutter環境を確認してください。"
        return 1
    fi

    log_success "Flutter SDK のセットアップ処理が完了しました" # メッセージを修正
}

# Flutter環境を検証
verify_flutter_setup() {
    log_start "Flutter環境を検証中..."
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
        log_error "Flutter環境の検証に失敗しました"
        return 1
    else
        log_success "Flutter環境の検証が完了しました"
        return 0
    fi
}

# Flutterのインストール確認
verify_flutter_installation() {
    if ! command_exists flutter; then
        log_error "Flutterがインストールされていません"
        return 1
    fi
    log_installed "Flutter"
    return 0
}

# Flutterのパス確認
verify_flutter_path() {
    FLUTTER_PATH=$(which flutter)
    log_info "Flutter PATH: $FLUTTER_PATH"
    
    # FVM管理下のパスを期待する
    local expected_fvm_path="$HOME/fvm/default/bin/flutter"
    if [[ "$FLUTTER_PATH" != "$expected_fvm_path" ]]; then
        log_error "Flutterのパスが想定 (FVM) と異なります"
        log_error "期待: $expected_fvm_path"
        log_error "実際: $FLUTTER_PATH"
        return 1
    else
        log_success "Flutterのパスが正しく設定されています (FVM)"
        return 0
    fi
}

# Flutter環境の検証
verify_flutter_environment() {
    # IS_CI チェックを削除し、常に verify_flutter_full_environment を呼び出す
    verify_flutter_full_environment # 引数なしに変更
    return $?
}

# Flutter環境の検証 (常に flutter --version を使用)
verify_flutter_full_environment() {
    log_info "Flutter環境チェック (flutter --version) を実行中..." # メッセージを修正
    if ! flutter --version > /dev/null 2>&1; then
        log_error "flutter --version の実行に失敗しました"
        return 1
    fi
    log_success "Flutterコマンドが正常に動作しています"
    
    return 0
} 