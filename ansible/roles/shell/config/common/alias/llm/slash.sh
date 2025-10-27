# shellcheck disable=SC2148
# Generate slash command aliases for easy clipboard access.

eval "$(gen_slash_aliases.py)"

sl-ls() {
	gen_slash_aliases.py --list
}
