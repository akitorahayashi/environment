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
    
    if [ -n "$version" ] && [ "$version" != "latest" ]; then
        echo "📦 ${package}@${version} をインストール中..."
    else
        echo "📦 ${package} をインストール中..."
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