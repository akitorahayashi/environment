#!/bin/bash
alias j="jj"

# Auto-generated jj aliases from jj config
generate_jj_aliases() {
	# Get all jj aliases and convert them to zsh aliases with 'j' prefix
	jj config list | grep '^aliases\.' | sed 's/^aliases\.\([^ ]*\) = .*/alias j\1="jj \1"/'
}

# Generate and source jj aliases
eval "$(generate_jj_aliases)"
