#!/bin/bash
alias al="alias"
al-c() {
	if [[ $# -eq 0 ]]; then
		echo "Usage: al-c <alias_name>"
		return 1
	fi
	local alias_value
	alias_value=$(alias "$1" 2>/dev/null | cut -d= -f2- | sed "s/^'//;s/'$//")
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
alias ex="exit"
alias wch="which"
alias tc="touch"
alias mkd="mkdir -p"
alias rel="source ~/.zshrc"
alias cl="clear"
alias tmp="echo 'template' | pbcopy && echo '✅ Copied \"template\" to clipboard'"
alias pcp="echo 'pbcopy' | pbcopy && echo '✅ Copied \"pbcopy\" to clipboard'"
alias gip="ipconfig getifaddr"
alias u="cd .."
alias uu="cd ../.."
alias uuu="cd ../../.."
alias rt='cd "${SHELL_START_DIR}"'
