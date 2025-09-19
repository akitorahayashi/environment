#!/bin/bash

unset RBENV_VERSION

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# Installing dependencies
echo "[INFO] Checking and installing dependencies: openssl, rbenv"
changed=false

# Install openssl first to prevent Ruby compilation errors
if ! brew list openssl >/dev/null 2>&1 && ! brew list openssl@3 >/dev/null 2>&1; then
    echo "[INSTALL] openssl (for Ruby compilation)"
    if brew install openssl; then
        echo "[SUCCESS] openssl installed"
        changed=true
    else
        echo "[ERROR] openssl installation failed"
        exit 1
    fi
fi

# Install rbenv (ruby-build is installed automatically as a dependency)
if ! command -v rbenv &> /dev/null; then
    echo "[INSTALL] rbenv"
    if brew install rbenv; then
        echo "[SUCCESS] rbenv installed (ruby-build also installed automatically)"
        changed=true
        eval "$(rbenv init -)"
        rbenv rehash
    else
        echo "[ERROR] rbenv installation failed"
        exit 1
    fi
fi

echo "==== Start: Starting Ruby environment setup..."

# Initialize rbenv so that rbenv Ruby is used for subsequent commands
eval "$(rbenv init -)"

# Read Ruby version from .ruby-version file
RUBY_VERSION_FILE="$CONFIG_DIR_PROPS/ruby/.ruby-version"
if [ ! -f "$RUBY_VERSION_FILE" ]; then
    echo "[ERROR] .ruby-version file not found: $RUBY_VERSION_FILE"
    exit 1
fi
RUBY_VERSION="$(tr -d '[:space:]' < "$RUBY_VERSION_FILE")"
readonly RUBY_VERSION
if [ -z "$RUBY_VERSION" ]; then
    echo "[ERROR] Failed to read version from .ruby-version file."
    exit 1
fi
    echo "[INFO] The Ruby version specified in .ruby-version is ${RUBY_VERSION}."# Install the specified version of Ruby if not already installed
if ! rbenv versions --bare | grep -q "^${RUBY_VERSION}$"; then
    echo "[INSTALL] Ruby ${RUBY_VERSION}"
    # openssl@3 を優先し、なければフォールバック
    if brew list --versions openssl@3 >/dev/null 2>&1; then
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@3)"
    else
        export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl)"
    fi
    if ! rbenv install -s "${RUBY_VERSION}"; then
        echo "[ERROR] Ruby ${RUBY_VERSION} installation failed"
        exit 1
    fi
    unset RUBY_CONFIGURE_OPTS
    changed=true
else
    echo "[INFO] Ruby ${RUBY_VERSION} is already installed"
fi

# Set the global version to the specified version
if [ "$(rbenv global)" != "${RUBY_VERSION}" ]; then
    echo "[CONFIG] Setting rbenv global to ${RUBY_VERSION}"
    rbenv global "${RUBY_VERSION}"
    rbenv rehash
    changed=true
else
    echo "[INFO] rbenv global is already set to ${RUBY_VERSION}"
fi

# gemのインストール処理
gem_file="$CONFIG_DIR_PROPS/ruby/global-gems.rb"
if [ ! -f "$gem_file" ]; then
    echo "[INFO] global-gems.rb not found. Skipping gem installation"
else
    readonly BUNDLER_VERSION="2.5.22"
    echo "[INFO] Checking Bundler version... (required: ${BUNDLER_VERSION})"
    current_version=$(bundle -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[a-zA-Z0-9]+)*' || echo "not-installed")

    if [ "$current_version" != "$BUNDLER_VERSION" ]; then
        echo "[INSTALL] Installing Bundler v${BUNDLER_VERSION}..."
        if gem install bundler -v "${BUNDLER_VERSION}" --no-document; then
            changed=true
        else
            echo "[ERROR] Bundler v${BUNDLER_VERSION} installation failed"
            exit 1
        fi
        rbenv rehash
    else
        echo "[INFO] Bundler is already version ${BUNDLER_VERSION}"
    fi
fi

# 最終的な環境情報を表示
bundler_version=$(bundle -v 2>/dev/null || echo 'bundler未インストール')
echo "[INFO] Ruby environment: $(ruby -v) / $(gem -v) / ${bundler_version}"
echo "[SUCCESS] Ruby environment setup completed"

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "==== Start: Verifying Ruby environment..."
# rbenv check
if ! command -v rbenv >/dev/null 2>&1; then
    echo "[ERROR] rbenv command not found"
    exit 1
fi
# rbenvが関数としてロードされているか確認
if ! type rbenv | grep -q 'function'; then
    eval "$(rbenv init -)"
fi

echo "[SUCCESS] rbenv: $(rbenv --version)"

# Rubyバージョンチェック
if [ "$(rbenv version-name)" != "${RUBY_VERSION}" ]; then
    echo "[ERROR] Ruby version is not ${RUBY_VERSION}"
    exit 1
else
    echo "[SUCCESS] Ruby: $(ruby -v)"
fi

# bundlerチェック
if ! command -v bundle >/dev/null 2>&1; then
    echo "[ERROR] bundler command not found"
    exit 1
fi

# bundlerのバージョンが指定通りであることを確認
current_version=$(bundle -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[a-zA-Z0-9]+)*' || echo "not-installed")

if [ "$current_version" != "$BUNDLER_VERSION" ]; then
    echo "[ERROR] bundler version mismatch. Expected: ${BUNDLER_VERSION}, Current: ${current_version}"
    exit 1
else
    echo "[SUCCESS] bundler: $(bundle -v)"
fi

echo "[SUCCESS] Ruby environment verification completed"