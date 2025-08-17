# This file is for machine-specific settings.
# It sources the common .zprofile file.

# Source the common .zprofile from the repository using a path relative to this script.
# This resolves symlinks to find the real script path, and works in both interactive and non-interactive shells.
COMMON_ZPROFILE_PATH="$(dirname "$(readlink "${(%):-%x}")")/../../common/shell/.zprofile"
if [ -f "$COMMON_ZPROFILE_PATH" ]; then
  source "$COMMON_ZPROFILE_PATH"
else
  echo "Error: Common .zprofile not found at $COMMON_ZPROFILE_PATH" >&2
  return 1
fi

# Add any machine-specific profile settings below this line.