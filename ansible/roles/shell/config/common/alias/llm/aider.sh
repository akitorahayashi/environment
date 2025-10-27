#!/bin/bash

# ==============================================================================

# Aider Chat Aliases and Functions

# ==============================================================================

# --- Core aider functions with Ollama models ---

# Base aider command with environment variable model

# Usage: ai [files...]

ai() {
	aider.py "$@"
}

ai-st() {
	local _output
	if ! _output="$(aider.py set-model "$1")"; then
		return $?
	fi
	eval "$_output"
}

ai-us() {
	local _output
	if ! _output="$(aider.py unset-model)"; then
		return $?
	fi
	eval "$_output"
}

ai-ls() {
	aider.py list-models "$@"
}
