# Aider
ai-st() {
  export OLLAMA_API_BASE="$1"
}
ai-ch() {
  local model="${1:?usage: ai-lch <model> [aider-args...]}"
  shift
  aider --model "ollama/$model" --no-auto-commit --no-gitignore "$@"
}