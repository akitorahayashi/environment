# This file is for machine-specific settings.
# It sources the common .zprofile file.

# When sourced, Zsh sets ${(%):-%N} to the path of the script (zsh).
# :A で絶対パス化+リンク解決
SOURCE_PATH=${(%):-%N:A}

# Get the directory of the source file.
# e.g., /path/to/repo/config/macbook-only/shell
SOURCE_DIR=${SOURCE_PATH:h}

# The REPO_ROOT is three directories up from this script's original location.
# e.g., from /path/to/repo/config/macbook-only/shell
export REPO_ROOT="${SOURCE_DIR:h:h:h}"

# Source the common .zprofile from the repository.
COMMON_ZPROFILE="$REPO_ROOT/config/common/shell/.zprofile"
if [ -f "$COMMON_ZPROFILE" ]; then
  source "$COMMON_ZPROFILE"
else
  echo "Error: Common .zprofile not found at $COMMON_ZPROFILE" >&2
  return 1
fi

# Add any machine-specific profile settings below this line.
# Example: export MY_VAR="some_value"

# Clean up temporary variables.
unset SOURCE_PATH SOURCE_DIR COMMON_ZPROFILE
