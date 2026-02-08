#!/bin/bash

# ==============================================================================

# Aider Chat Aliases and Functions

# ==============================================================================

# --- Core aider functions with Ollama models ---

# Base aider command with environment variable model

# Usage: ai [files...]

ai() {
	menv internal aider run "$@"
}

ai-st() {
	local _output
	if ! _output="$(menv internal aider set-model "$1")"; then
		return $?
	fi
	eval "$_output"
}

ai-us() {
	local _output
	if ! _output="$(menv internal aider unset-model)"; then
		return $?
	fi
	eval "$_output"
}

ai-ls() {
	menv internal aider list-models "$@"
}
