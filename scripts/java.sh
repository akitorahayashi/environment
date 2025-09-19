#!/bin/bash

# Define the JDK version to use as a constant
readonly JDK_VERSION="21"

echo "==== Start: Starting Java environment setup..."

# temurin@<バージョン>がインストールされていなければインストール
if ! brew list --cask "temurin@${JDK_VERSION}" > /dev/null 2>&1; then
    echo "[INSTALL] temurin@${JDK_VERSION}"
    brew_install_cmd=("brew" "install" "--cask")
    if [ "${CI:-false}" = "true" ]; then
        brew_install_cmd+=("--no-quarantine")
    fi

    if ! "${brew_install_cmd[@]}" "temurin@${JDK_VERSION}"; then
        echo "[ERROR] temurin@${JDK_VERSION} installation failed"
        exit 1
    fi
    echo "IDEMPOTENCY_VIOLATION" >&2
else
    echo "[INFO] temurin@${JDK_VERSION} is already installed"
fi

echo "[SUCCESS] Java environment setup completed"


# JAVA_HOME の設定
if [ -x /usr/libexec/java_home ]; then
  JAVA_HOME_PATH=$(/usr/libexec/java_home -v "${JDK_VERSION}" 2>/dev/null)
  if [ -n "$JAVA_HOME_PATH" ]; then
    export JAVA_HOME="$JAVA_HOME_PATH"
  else
    echo "[WARNING] Java ${JDK_VERSION} not found. Skipping JAVA_HOME setup." >&2
  fi
else
  echo "[WARNING] /usr/libexec/java_home not available. Skipping JAVA_HOME setup." >&2
fi

echo "==== Start: Verifying Java environment..."

# temurinがインストールされているか確認
if ! brew list --cask "temurin@${JDK_VERSION}" > /dev/null 2>&1; then
    echo "[ERROR] temurin@${JDK_VERSION} is not installed"
    exit 1
else
    echo "[SUCCESS] temurin@${JDK_VERSION} is installed"
fi

# JAVA_HOMEが設定されているか確認
if [ -z "${JAVA_HOME:-}" ]; then
    echo "[ERROR] JAVA_HOME is not set"
    exit 1
else
    echo "[SUCCESS] JAVA_HOME is set: $JAVA_HOME"
fi

# javaコマンドが実行できるか確認
if ! java -version > /dev/null 2>&1; then
    echo "[ERROR] java command cannot be executed"
    exit 1
else
    echo "[SUCCESS] java command is executable: $(java -version 2>&1 | head -n 1)"
fi

echo "[SUCCESS] Java environment verification completed"