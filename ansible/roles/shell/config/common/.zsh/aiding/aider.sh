#!/bin/bash
# ==============================================================================
# Aider Chat Aliases and Functions
# ==============================================================================

# --- Core aider functions with Ollama models ---

# Base aider command with environment variable model
# Usage: ai [files...]
ai() {
	local model=${AIDER_OLLAMA_MODEL:?Please set AIDER_OLLAMA_MODEL environment variable (use: ai-st <model_name>)}
	local files=()
	local directories=()
	local show_help=false
	local yolo_mode=false
	local message=""

	# Parse options
	while [[ $# -gt 0 ]]; do
		case $1 in
		-d | --dir)
			shift
			if [[ $# -eq 0 || "$1" == -* ]]; then
				echo "Error: -d requires a directory path"
				return 1
			fi
			directories+=("$1")
			shift
			;;
		-e | --ext)
			shift
			if [[ $# -eq 0 || "$1" == -* ]]; then
				echo "Error: -e requires an extension"
				return 1
			fi
			# Add files by extension recursively
			local ext=${1#.} # Remove leading dot if present
			while IFS= read -r -d '' file; do
				files+=("$file")
			done < <(find . -name "*.$ext" -type f -print0 2>/dev/null)
			shift
			;;
		-f | --files)
			shift
			while [[ $# -gt 0 && "$1" != -* ]]; do
				files+=("$1")
				shift
			done
			;;
		-y | --yes)
			yolo_mode=true
			shift
			;;
		-m | --message)
			shift
			if [[ $# -eq 0 || "$1" == -* ]]; then
				echo "Error: -m requires a message"
				return 1
			fi
			message="$1"
			shift
			;;
		-h | --help)
			show_help=true
			shift
			;;
		-*)
			echo "Unknown option: $1"
			show_help=true
			break
			;;
		*)
			files+=("$1")
			shift
			;;
		esac
	done

	if [[ "$show_help" == true ]]; then
		echo "Usage: ai [options] [files...]"
		echo "Options:"
		echo "  (no options)    Use all project files (default)"
		echo "  -d, --dir <dir> Add directory recursively"
		echo "  -e, --ext <ext> Add files by extension recursively"
		echo "  -f, --files <files...> Add specific files only"
		echo "  -y, --yes       YOLO mode (auto-accept all changes)"
		echo "  -m, --message <msg> Send message and exit (non-interactive)"
		echo "  -h, --help      Show this help"
		echo ""
		echo "Examples:"
		echo "  ai                        # All project files"
		echo "  ai -d src                 # All files in src/ directory recursively"
		echo "  ai -e md                  # All .md files recursively"
		echo "  ai -e js                  # All .js files recursively"
		echo "  ai -f main.py utils.py    # Specific files only"
		echo "  ai -y -d src              # YOLO mode with src/ directory"
		echo "  ai -y -m \"analyze\" -d src   # YOLO + message + directory"
		echo "  ai main.py utils.py       # Same as -f (shorthand)"
		return 0
	fi

	# Build aider command safely as an array (no eval)
	local provider_model
	if [[ "$model" == */* ]]; then
		provider_model="$model"
	else
		provider_model="ollama/$model"
	fi
	local cmd=(aider --model "$provider_model" --no-auto-commit --no-gitignore)

	if [[ "$yolo_mode" == true ]]; then
		cmd+=(--yes)
	fi

	if [[ -n "$message" ]]; then
		cmd+=(--message "$message")
	fi

	# Build file list: combine files from -e, -f, and direct args
	local all_files=("${files[@]}")

	# Add directories (handled internally by aider)
	if [[ ${#directories[@]} -gt 0 ]]; then
		for dir in "${directories[@]}"; do
			all_files+=("$dir")
		done
	fi

	# Default: start without explicit files if none specified
	if [[ ${#all_files[@]} -eq 0 ]]; then
		command "${cmd[@]}"
	else
		command "${cmd[@]}" "${all_files[@]}"
	fi
}

# Set default Ollama model for aider
# Usage: ai-st qwen3:0.6b
ai-st() {
	if [[ $# -ne 1 ]]; then
		echo "Usage: ai-st <model_name>"
		echo "Current AIDER_OLLAMA_MODEL: ${AIDER_OLLAMA_MODEL:-not set}"
		return 1
	fi

	export AIDER_OLLAMA_MODEL="$1"
	echo "✅ Set AIDER_OLLAMA_MODEL to: $1"
}

# Unset Ollama model for aider
# Usage: ai-us
ai-us() {
	if [[ -n "$AIDER_OLLAMA_MODEL" ]]; then
		unset AIDER_OLLAMA_MODEL
		echo "✅ Unset AIDER_OLLAMA_MODEL"
	else
		echo "AIDER_OLLAMA_MODEL is already not set"
	fi
}

# List available Ollama models
ai-ls() {
	if command -v ollama >/dev/null 2>&1; then
		echo "Available Ollama models for aider:"
		ollama list | tail -n +2 | awk '{print "  " $1}' | sort
		echo ""
		echo "Usage: ai-st <model> && ai [files...]"
		echo "Example: ai-st llama3.2 && ai main.py"
		echo ""
		echo "Current AIDER_OLLAMA_MODEL: ${AIDER_OLLAMA_MODEL:-not set}"
	else
		echo "Ollama is not installed"
	fi
}
