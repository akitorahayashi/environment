#!/bin/bash

# ログ出力
log_info() {
    echo "ℹ️ $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️ $1"
}

log_error() {
    echo "❌ $1"
}

log_start() {
    echo "🔄 $1"
}

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
    
    # 冪等性チェック（該当関数が定義されている場合のみ実行）
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
        # ヘルパー関数がロードされている場合のみ実行
        if type check_idempotence >/dev/null 2>&1; then
            check_idempotence "$package" "$message"
        fi
    fi
}

log_installed() {
    local package="$1"
    local version="${2:-}"
    
    if [ -n "$version" ] && [ "$version" != "latest" ]; then
        echo "✅ ${package}@${version} はすでにインストール済みです"
    else
        echo "✅ ${package} はすでにインストール済みです"
    fi
}

log_ci_marker() {
    echo "インストール中"
}

# エラーを処理する
handle_error() {
    log_error "$1"
    log_error "スクリプトを終了します。"
    exit 1
} 