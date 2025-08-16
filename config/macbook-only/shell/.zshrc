# This file is for machine-specific settings.
# It sources the common .zshrc file.

# When sourced, Zsh sets ${(%):-%N} to the path of the script.
# This works even for symlinks.
SOURCE_PATH=${(%):-%N}

# If it's a symlink, resolve it to the actual file path in the repo.
# $HOME/.zshrc -> /path/to/repo/config/macbook-only/shell/.zshrc
if [[ -L "$SOURCE_PATH" ]]; then
  SOURCE_PATH=$(readlink "$SOURCE_PATH")
fi

# Get the directory of the source file.
# e.g., /path/to/repo/config/macbook-only/shell
SOURCE_DIR=$(dirname "$SOURCE_PATH")

# The REPO_ROOT is three directories up from this script's original location.
# e.g., from /path/to/repo/config/macbook-only/shell
REPO_ROOT=$(cd "$SOURCE_DIR/../../.."; pwd)

# Source the common .zshrc from the repository.
COMMON_ZSHRC="$REPO_ROOT/config/common/shell/.zshrc"
if [ -f "$COMMON_ZSHRC" ]; then
  source "$COMMON_ZSHRC"
else
  echo "Error: Common .zshrc not found at $COMMON_ZSHRC" >&2
fi

# Add any machine-specific zshrc settings below this line.
# Example: alias myalias="echo 'hello'"
