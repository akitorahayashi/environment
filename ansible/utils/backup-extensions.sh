#!/bin/bash
set -euo pipefail

# Get the configuration directory path from script arguments
# Validate that at least one argument is provided
if [ $# -lt 1 ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi
CONFIG_DIR="$1"
# Validate that the provided argument is not an empty string
if [ -z "${1-}" ]; then
    echo "[ERROR] This script requires a non-empty configuration directory path as its first argument." >&2
    exit 1
fi

# ================================================
# Get the current VSCode extension list and generate extensions.json
# ================================================
#
# Usage:
# 1. Grant execution permission:
#    $ chmod +x ansible/utils/backup-extensions.sh
# 2. Run the script:
#    $ ./ansible/utils/backup-extensions.sh config/common
#
# The script will create/update config/common/vscode/extensions/extensions.json with the current list of VSCode extensions.
#
# ================================================

# Script to backup VSCode extensions list
# Backup file path

# Set output file path
EXT_FILE="$CONFIG_DIR/editor/vscode/extensions.json"
mkdir -p "$(dirname "$EXT_FILE")"

# Detect VSCode command
if command -v code >/dev/null 2>&1; then
  CODE_CMD="code"
elif [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  CODE_CMD="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
elif command -v code-insiders >/dev/null 2>&1; then
  CODE_CMD="code-insiders"
else
  echo "❌ VSCode command (code or code-insiders) not found." >&2
  exit 1
fi

# Get and save extensions list
echo "Getting VSCode extensions list..."
if ! extensions=$("$CODE_CMD" --list-extensions 2>&1); then
  echo "❌ Failed to get VSCode extensions." >&2
  echo "   Possible causes:" >&2
  echo "   - If VSCode is running, please close it and try again" >&2
  echo "   - VSCode installation may have issues" >&2
  echo "   - Command: $CODE_CMD --list-extensions" >&2
  echo "   Error output: $extensions" >&2
  exit 1
fi

json="{\"extensions\": ["
for ext in $extensions; do
  json+="\"$ext\","
done
json=${json%,}
json+="]}"
echo "$json" | python3 -m json.tool > "$EXT_FILE"
echo "VSCode extensions list backed up to: $EXT_FILE"