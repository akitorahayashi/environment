# This file is for machine-specific settings.
# It sources the common .zshrc file.

# When sourced, Zsh sets ${(%):-%N} to the path of the script (zsh).
# :A で絶対パス化+リンク解決
SOURCE_PATH=${(%):-%N:A}

# Get the directory of the source file.
# e.g., /path/to/repo/config/mac-mini-only/shell
SOURCE_DIR=${SOURCE_PATH:h}

# The REPO_ROOT is three directories up from this script's original location.
# e.g., from /path/to/repo/config/mac-mini-only/shell
REPO_ROOT="${SOURCE_DIR:h:h:h}"

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
