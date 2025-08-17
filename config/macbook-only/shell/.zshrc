# This file is for machine-specific settings.
# It sources the common .zshrc file.

# Source the common .zshrc from the repository using a relative path from project root.
COMMON_ZSHRC="config/common/shell/.zshrc"
if [[ -f "$COMMON_ZSHRC" ]]; then
  # Avoid double-loading when re-sourcing .zshrc.
  if [[ -z "${__ENV_COMMON_ZSHRC_SOURCED-}" ]]; then
    export __ENV_COMMON_ZSHRC_SOURCED=1
    source "$COMMON_ZSHRC"
  fi
else
  echo "Error: Common .zshrc not found at $COMMON_ZSHRC" >&2
  return 1
fi

# Add any machine-specific zshrc settings below this line.
