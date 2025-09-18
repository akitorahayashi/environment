#!/bin/bash

# REPO_ROOT is not used in this script, but defined in Makefile for consistency.

# Function to log messages with consistent formatting
log_info() { echo "[INFO] $1"; }
log_success() { echo "[SUCCESS] $1"; }
log_error() { echo "[ERROR] $1"; }

# Function to check if FVM Flutter path is correct
verify_flutter_path() {
    local flutter_path=$(which flutter)
    local expected_path="$HOME/fvm/default/bin/flutter"

    log_info "Flutter PATH: $flutter_path"

    if [[ "$flutter_path" != "$expected_path" ]]; then
        log_error "Flutter path mismatch"
        log_error "Expected: $expected_path"
        log_error "Actual: $flutter_path"
        return 1
    fi

    log_success "Flutter path is correctly configured"
    return 0
}

# Function to verify Flutter installation
verify_flutter() {
    if ! command -v flutter >/dev/null 2>&1; then
        log_error "Flutter command not found"
        return 1
    fi

    if ! verify_flutter_path; then
        return 1
    fi

    if ! flutter --version > /dev/null 2>&1; then
        log_error "flutter --version failed"
        log_info "Try running 'flutter doctor' for detailed diagnostics"
        return 1
    fi

    log_success "Flutter is working correctly"
    return 0
}

# Install FVM dependency
log_info "Checking and installing dependency: fvm"
if ! command -v fvm &> /dev/null; then
    brew tap leoafarias/fvm
    brew install leoafarias/fvm/fvm
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

log_info "Starting Flutter SDK setup using fvm"

changed=false
fvm_stable_path="$HOME/fvm/versions/stable"
fvm_default_link="$HOME/fvm/default"

# Install stable Flutter SDK (fvm install is idempotent)
log_info "Installing stable Flutter SDK..."
was_already_installed=false
if [ -d "$fvm_stable_path" ]; then
    was_already_installed=true
fi

if fvm install stable; then
    if [ "$was_already_installed" = false ]; then
        changed=true
        log_success "Flutter SDK (stable) newly installed"
    else
        log_success "Flutter SDK (stable) already installed"
    fi
else
    log_error "fvm install stable failed"
    exit 1
fi

# Set global Flutter version to stable if not already set
if [ -L "$fvm_default_link" ] && [ "$(readlink "$fvm_default_link")" == "$fvm_stable_path" ]; then
    log_success "fvm global is already set to stable, skipping"
else
    log_info "Setting fvm global stable..."
    if fvm global stable; then
        log_success "fvm global stable configuration completed"
        changed=true
    else
        log_error "fvm global stable configuration failed"
        exit 1
    fi
fi

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# Update PATH to use FVM-managed Flutter
export PATH="$HOME/fvm/default/bin:$PATH"
log_info "Added fvm path to current shell session PATH"

# Verify Flutter environment
log_info "Verifying Flutter environment..."
if verify_flutter; then
    log_success "Flutter environment setup and verification completed"
else
    log_error "Flutter environment verification failed"
    exit 1
fi