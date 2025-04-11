#!/bin/bash

# 情報ログ
log_info() {
    echo "ℹ️ $1"
}

# 成功ログ
log_success() {
    echo "✅ $1"
}

# 警告ログ
log_warning() {
    echo "⚠️ $1"
}

# 処理開始ログ
log_start() {
    echo "🚀 $1"
}

# エラーログ
log_error() {
    echo "❌ $1"
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
        message="${package}@${version} をインストール中..."
        echo "📦 $message"
    else
        message="${package} をインストール中..."
        echo "📦 $message"
    fi
    
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
    local version="${2:-}"
    
    if [ -n "$version" ] && [ "$version" != "latest" ]; then
        echo "✅ ${package}@${version} はすでにインストール済みです"
    else
        echo "✅ ${package} はすでにインストール済みです"
    fi
}
