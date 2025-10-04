#!/bin/bash
# shellcheck disable=SC1090,SC1091
# venv
act() {
	if [[ $# -eq 1 ]]; then
		source "./$1/bin/activate"
	else
		source "./.venv/bin/activate"
	fi
}
alias dct='deactivate'
rm-vev() {
	if [[ $# -eq 1 ]]; then
		rm -rf "./$1"
	else
		rm -rf "./.venv"
	fi
}
