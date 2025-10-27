# shellcheck disable=SC2148
# Generate slash command aliases for easy clipboard access.

if [ -f "$MENV_DIR/ansible/scripts/shell/gen_slash_aliases.py" ]; then
	eval "$(gen_slash_aliases.py)"
fi

sl-ls() {
	if [ -f "$MENV_DIR/ansible/scripts/shell/gen_slash_aliases.py" ]; then
		gen_slash_aliases.py --list
	else
		alias | grep '^sl-' | sed 's/^alias //'
	fi
}
