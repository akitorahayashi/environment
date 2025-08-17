# This file is for machine-specific settings.
# It sources the common .zprofile file.

# Source the common .zprofile from the repository using a relative path from project root.
COMMON_ZPROFILE="config/common/shell/.zprofile"
if [ -f "$COMMON_ZPROFILE" ]; then
  source "$COMMON_ZPROFILE"
else
  echo "Error: Common .zprofile not found at $COMMON_ZPROFILE" >&2
  return 1
fi

# Add any machine-specific profile settings below this line.
