# This file is for machine-specific settings.
# It sources the common .zprofile file.

# When sourced, Zsh sets ${(%):-%N} to the path of the script.
# This works even for symlinks.
SOURCE_PATH=${(%):-%N}

# If it's a symlink, resolve it to the actual file path in the repo.
# $HOME/.zprofile -> /path/to/repo/config/mac-mini-only/shell/.zprofile
if [[ -L "$SOURCE_PATH" ]]; then
  SOURCE_PATH=$(readlink "$SOURCE_PATH")
fi

# Get the directory of the source file.
# e.g., /path/to/repo/config/mac-mini-only/shell
SOURCE_DIR=$(dirname "$SOURCE_PATH")

# The REPO_ROOT is three directories up from this script's original location.
# e.g., from /path/to/repo/config/mac-mini-only/shell
export REPO_ROOT=$(cd "$SOURCE_DIR/../../.."; pwd)

# Source the common .zprofile from the repository.
COMMON_ZPROFILE="$REPO_ROOT/config/common/shell/.zprofile"
if [ -f "$COMMON_ZPROFILE" ]; then
  source "$COMMON_ZPROFILE"
else
  echo "Error: Common .zprofile not found at $COMMON_ZPROFILE" >&2
fi

# Add any machine-specific profile settings below this line.
# Example: export MY_VAR="some_value"
