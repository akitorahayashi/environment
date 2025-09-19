#!/bin/bash

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# Install dependencies
echo "[INFO] Checking and installing dependencies: visual-studio-code"
if ! brew list --cask visual-studio-code &> /dev/null; then
    brew install --cask visual-studio-code
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "[Start] Starting VS Code setup..."
config_dir="$CONFIG_DIR_PROPS/vscode"
vscode_target_dir="$HOME/Library/Application Support/Code/User"

# Check if the configuration files exist in the repository
if [ ! -d "$config_dir" ]; then
    echo "[WARN] Configuration directory not found: $config_dir"
    echo "[INFO] Skipping VS Code configuration setup."
    exit 0
fi

# Check if Visual Studio Code is installed
if [ ! -d "/Applications/Visual Studio Code.app" ]; then
    echo "[WARN] Visual Studio Code is not installed. Skipping."
    exit 0 # Not an error if it's not installed
fi
echo "[SUCCESS] Visual Studio Code is already installed"

# Create target directory
mkdir -p "$vscode_target_dir"

# Create symbolic links for configuration files
shopt -s nullglob
for file in "$config_dir"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        target_file="$vscode_target_dir/$filename"

        # Create symbolic link
        if ln -sf "$file" "$target_file"; then
            echo "[SUCCESS] Created symbolic link for VS Code configuration file $filename."
        else
            echo "[ERROR] Failed to create symbolic link for VS Code configuration file $filename."
            exit 1
        fi
    fi
done
shopt -u nullglob

echo "[SUCCESS] VS Code environment setup completed"

echo ""
echo "==== Start: Verifying VS Code environment... ===="
verification_failed=false
config_dir="$CONFIG_DIR_PROPS/vscode"
vscode_target_dir="$HOME/Library/Application Support/Code/User"

# Skip verification if no configuration files in the repository
if [ ! -d "$config_dir" ]; then
    echo "[INFO] Skipping configuration verification as no VS Code settings found in repository."
    exit 0
fi

# Check if symbolic links are correctly created
linked_files=0
shopt -s nullglob
for file in "$config_dir"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        target_file="$vscode_target_dir/$filename"

        if [ -L "$target_file" ]; then
            link_target=$(readlink "$target_file")
            if [ "$link_target" = "$file" ]; then
                echo "[OK] VS Code configuration file $filename is correctly linked."
                ((linked_files++))
            else
                echo "[ERROR] Invalid link target for VS Code configuration file $filename: $link_target (expected: $file)"
                verification_failed=true
            fi
        else
            echo "[ERROR] Symbolic link for VS Code configuration file $filename not created."
            verification_failed=true
        fi
    fi
done

if [ "$linked_files" -eq 0 ]; then
    echo "[ERROR] No symbolic links created for VS Code."
    verification_failed=true
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] VS Code environment verification failed"
    exit 1
else
    echo "[OK] VS Code environment verification completed"
fi