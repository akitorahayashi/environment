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

# エラーを処理する
handle_error() {
    log_error "$1"
    log_error "スクリプトを終了します。"
    exit 1
} 