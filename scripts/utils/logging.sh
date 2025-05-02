#!/bin/bash

# 情報ログ
log_info() {
    echo "[INFO] $1"
}

# 成功ログ
log_success() {
    echo "[OK] $1"
}

# 警告ログ
log_warning() {
    echo "[WARN] $1"
}

# 処理開始ログ
log_start() {
    echo "" # 改行
    echo "==== Start: $1 ===="
}

# エラーログ
log_error() {
    echo "[ERROR] $1"
}

# エラー処理
handle_error() {
    log_error "$1"
    log_error "スクリプトを終了します。"
    exit 1
} 

# インストール中ログ
log_installing() {
    local package="$1"
    local version="${2:-}"
    local message=""
    
    if [ -n "$version" ] && [ "$version" != "latest" ]; then
        message="${package}@${version}"
    else
        message="${package}"
    fi
    echo "[INSTALL] $message ..."
    
    # 冪等性チェック
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
        # ヘルパー関数がロードされている場合のみ実行
        if type check_idempotence >/dev/null 2>&1; then
            check_idempotence "$package" "$message"
        fi
    fi
}

# インストール済みログ
log_installed() {
    local package="$1"
    echo "[OK] ${package} ... already installed"
}

