# This file is for machine-specific settings.
# It sources the common .zshrc file.

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

# Source the common .zshrc from the repository.
COMMON_ZSHRC="$REPO_ROOT/config/common/shell/.zshrc"
if [[ -f "$COMMON_ZSHRC" ]]; then
  # Avoid double-loading when re-sourcing .zshrc.
  if [[ -z "${__ENV_COMMON_ZSHRC_SOURCED-}" ]]; then
    typeset -g __ENV_COMMON_ZSHRC_SOURCED=1
    source "$COMMON_ZSHRC"
  fi
else
  print -ru2 -- "Error: Common .zshrc not found at $COMMON_ZSHRC"
  return 1
fi

# Add any machine-specific zshrc settings below this line.
# Example: alias myalias="echo 'hello'"

# Clean up temporary variables.
unset SOURCE_PATH SOURCE_DIR COMMON_ZSHRC