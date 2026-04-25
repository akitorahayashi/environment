#!/bin/bash
# pytest
alias pts="pytest"

ws() {
	local input_dir
	local filename
	input_dir=$(dirname "$1")
	filename=$(basename "$1" .mp4)
	local output_dir="${input_dir}/.whisper/${filename}"
	mkdir -p "$output_dir"

	whisper "$@" \
		--language Japanese \
		--model medium \
		--output_dir "$output_dir" \
		--output_format all \
		--word_timestamps True \
		--temperature 0
}

# black
alias bl="black ."
alias bl-chk="black --check ."

# ruff
alias rf="ruff check . --fix"
alias rf-chk="ruff check ."

# python project cleanup
py-cln() {
	echo "🧹 Cleaning up project..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	rm -rf .venv
	rm -rf .pytest_cache
	rm -rf .ruff_cache
	echo "✅ Cleanup completed"
}

# venv
act() {
	if [[ $# -eq 1 ]]; then
		# shellcheck disable=SC1090,SC1091
		source "./$1/bin/activate"
	else
		# shellcheck disable=SC1091
		source "./.venv/bin/activate"
	fi
}
alias dct='deactivate'
