ai-st() {
  export OLLAMA_API_BASE="$1"
}
ai-ch() {
  local model="${1:?usage: ai-lch <model> [aider-args...]}"
  shift
  aider --model "ollama/$model" --no-auto-commit --no-gitignore "$@"
}
ai-ls() {
  if command -v ollama >/dev/null 2>&1; then
    echo "Ollama models:"
    ollama list
  else
    echo "Ollama is not installed"
  fi
}
