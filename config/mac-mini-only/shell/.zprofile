# This file is for machine-specific settings.
# It sources the common .zprofile file.

# If REPO_ROOT is not set, determine it from the script's location.
if [ -z "$REPO_ROOT" ]; then
  # When sourced, Zsh sets ${(%):-%x} to the path of the sourced script.
  # :A resolves the absolute path, including any symlinks.
  SOURCE_PATH=${(%):-%x:A}

  # Get the directory of the source file.
  # e.g., /path/to/repo/config/mac-mini-only/shell
  SOURCE_DIR=${SOURCE_PATH:h}

  # The REPO_ROOT is three directories up from this script's original location.
  # e.g., from /path/to/repo/config/mac-mini-only/shell
  export REPO_ROOT="${SOURCE_DIR:h:h:h}"
fi


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