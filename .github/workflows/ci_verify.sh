#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

# ユーティリティのロード
source "$ROOT_DIR/scripts/utils/helpers.sh"

# セットアップスクリプトをロード
source "$ROOT_DIR/scripts/setup/flutter.sh"
source "$ROOT_DIR/scripts/setup/homebrew.sh"
source "$ROOT_DIR/scripts/setup/xcode.sh"
source "$ROOT_DIR/scripts/setup/git.sh"
source "$ROOT_DIR/scripts/setup/ruby.sh"
source "$ROOT_DIR/scripts/setup/cursor.sh"
source "$ROOT_DIR/scripts/setup/shell.sh"
source "$ROOT_DIR/scripts/setup/mac.sh"
source "$ROOT_DIR/scripts/setup/reactnative.sh"

# CI環境でBREWFILEのパスを設定
BREWFILE_PATH="$ROOT_DIR/config/Brewfile"

# 検証機能の実行
run_all_verifications() {
    log_start "🧪 環境のセットアップ検証を開始します..."
    
    local failures=0
    local total_verifications=0
    
    # Homebrewの検証
    ((total_verifications++))
    log_info "Homebrew環境の検証を開始..."
    verify_homebrew_setup || ((failures++))
    
    # Brewfileパッケージの検証
    ((total_verifications++))
    log_info "Brewfileパッケージの検証を開始..."
    verify_brewfile_installation || ((failures++))
    
    # Xcodeの検証
    ((total_verifications++))
    log_info "Xcode環境の検証を開始..."
    verify_xcode_installation || ((failures++))
    
    # Gitの検証
    ((total_verifications++))
    log_info "Git環境の検証を開始..."
    verify_git_setup || ((failures++))
    
    # Ruby環境の検証
    ((total_verifications++))
    log_info "Ruby環境の検証を開始..."
    verify_ruby_setup || ((failures++))
    
    # Cursorの検証
    ((total_verifications++))
    log_info "Cursor環境の検証を開始..."
    verify_cursor_setup || ((failures++))
    
    # シェルの検証
    ((total_verifications++))
    log_info "シェル環境の検証を開始..."
    verify_shell_setup || ((failures++))

    # Macの検証
    ((total_verifications++))
    log_info "Mac環境の検証を開始..."
    verify_mac_setup || ((failures++))

    # Flutterの検証
    ((total_verifications++))
    log_info "Flutter環境の検証を開始..."
    verify_flutter_setup || ((failures++))
    
    # React Native環境の検証
    ((total_verifications++))
    log_info "React Native環境の検証を開始..."
    verify_reactnative_setup || ((failures++))
    
    # 結果のサマリーを表示
    log_info "======================="
    log_info "検証結果サマリー: $total_verifications 項目中 $((total_verifications - failures)) 項目が成功"
    
    if [ $failures -eq 0 ]; then
        log_success "🎉 すべての検証が成功しました！"
        return 0
    else
        log_error "❌ $failures 個の検証に失敗しました"
        return 1
    fi
}

# Homebrewのインストールを検証

# Xcodeのインストールを検証

# Brewfileに記載されたパッケージの検証


# このスクリプトが直接実行された場合のみ実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # CI環境変数を設定
    export IS_CI=true
    export ALLOW_COMPONENT_FAILURE=true
    
    # すべての検証を実行
    run_all_verifications
    exit $?
fi 