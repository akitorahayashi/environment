al() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: al <alias_name>"
    return 1
  fi
  local alias_value=$(alias "$1" 2>/dev/null | cut -d= -f2- | sed "s/^'//;s/'$//")
  if [[ -z "$alias_value" ]]; then
    echo "Alias '$1' not found."
    return 1
  fi
  echo "$alias_value" | pbcopy
  echo "✅ Copied '$alias_value' to clipboard"
}
alias sc="source"
alias ec="echo"
alias ct="cat"
alias wch="which"
alias tc="touch"
alias rel="source ~/.zshrc"
alias cl="clear"
alias tmp="echo 'template' | pbcopy && echo '✅ Copied \"template\" to clipboard'"
alias gip="ipconfig getifaddr"

sw() {
  [[ -z "$1" ]] && { echo "Usage: srch-w <pattern> [dir]"; return 1; }
  if git rev-parse --git-dir &>/dev/null && [[ -f .gitignore ]]; then
    git ls-files "${2:-.}" | xargs grep -l "$1" 2>/dev/null
  else
    find "${2:-.}" -type f ! -path "*/.*" ! -name "*.log" ! -name ".DS_Store" -exec grep -l "$1" {} \; 2>/dev/null
  fi
}
