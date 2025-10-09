# shellcheck disable=SC2148
# Generate slash command aliases for easy clipboard access.

if command -v gen_slash_aliases.py >/dev/null 2>&1; then
	eval "$(gen_slash_aliases.py)"
fi
