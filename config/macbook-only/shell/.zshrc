# This file is for machine-specific settings.
# It sources the common .zshrc file.

# Source the common .zshrc from the repository using a path relative to this script.
# This resolves symlinks to find the real script path, and works in both interactive and non-interactive shells.
COMMON_ZSHRC_PATH="$(dirname "$(readlink "${(%):-%x}")")/../../common/shell/.zshrc"
if [[ -f "$COMMON_ZSHRC_PATH" ]]; then
  # Avoid double-loading when re-sourcing .zshrc.
  if [[ -z "${__ENV_COMMON_ZSHRC_SOURCED-}" ]]; then
    export __ENV_COMMON_ZSHRC_SOURCED=1
    source "$COMMON_ZSHRC_PATH"
  fi
else
  echo "Error: Common .zshrc not found at $COMMON_ZSHRC_PATH" >&2
  return 1
fi

# Add any machine-specific zshrc settings below this line.

# Aider
aid-set() {
  export OLLAMA_API_BASE="$1"
}
aid-lch() {
  local model="${1:?usage: aid-lch <model> [aider-args...]}"
  shift
  aider --model "ollama/$model" --no-auto-commit --no-gitignore "$@"
}