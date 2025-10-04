alias u="uv"
alias u-ini="uv init"
u-v() {
	if [[ -f ".python-version" ]]; then
		pyver=$(<.python-version)
	else
		echo ".python-version not found. Exiting."
		return 1
	fi

	if ! pyenv versions --bare | grep -qx "$pyver"; then
		echo "Python $pyver is not installed. Installing..."
		pyenv install "$pyver"
	fi

	if [[ $# -eq 1 ]]; then
		uv venv "$1" --python "$(pyenv which python)"
	else
		uv venv --python "$(pyenv which python)"
	fi
}
alias u-a="uv add"
alias u-s="uv sync"
alias u-b="uv build"
alias u-s-e="uv sync --extra"
alias u-s-nd="uv sync --no-dev"
alias u-s-og="uv sync --only-group"
alias u-lk="uv lock"
alias u-rv="rm-vev;u-v;u-s"
alias u-r="uv run"
alias u-e="uv export --format requirements.txt > requirements.txt"

# uvx
alias ux="uvx"
alias ux-c="uvx cowsay -t"
