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
alias grp="grep"
alias fd="find . -name"
alias wch="which"
alias tc="touch"
alias rel="source ~/.zshrc"
alias cl="clear"
alias tmp="echo 'template' | pbcopy && echo '✅ Copied \"template\" to clipboard'"
alias gip="ipconfig getifaddr"
