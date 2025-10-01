# Makefile: The entrypoint for initial environment setup.
#
# This Makefile has two main steps:
# 1. `make base`: Installs Homebrew and Just.
# 2. `make macbook` or `make mac-mini`: Runs the actual setup using Just.

.DEFAULT_GOAL := help

.PHONY: help 
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[^_][a-zA-Z0-9_-]*:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: base
base: ## Installs Homebrew and the 'just' command runner
	@echo "🚀 Starting bootstrap setup..."

	@if command -v xcode-select &> /dev/null; then \
		if ! xcode-select -p &> /dev/null; then \
			echo "[INSTALL] Xcode Command Line Tools ..."; \
			xcode-select --install; \
		else \
			echo "[SUCCESS] Xcode Command Line Tools are already installed."; \
		fi; \
	else \
		echo "[ERROR] xcode-select command not found. This setup must run on macOS."; \
		exit 1; \
	fi

	@if [ ! -f .env ]; then \
		cp .env.example .env && \
		echo "📝 Created .env file from .env.example. Please edit PERSONAL_VCS_NAME and PERSONAL_VCS_EMAIL."; \
	else \
		echo "📝 .env file already exists."; \
	fi

	@if ! command -v brew &> /dev/null; then \
		echo "[INSTALL] Homebrew ..."; \
		echo "[INFO] Homebrewインストールスクリプトを実行します..."; \
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		if ! command -v brew &> /dev/null; then \
			echo "[ERROR] Homebrewのインストールに失敗しました"; \
			exit 1; \
		fi; \
		echo "[SUCCESS] Homebrew のインストール完了"; \
	else \
		echo "[SUCCESS] Homebrew はすでにインストールされています"; \
	fi

	@if command -v brew &> /dev/null; then \
		eval "$$(brew shellenv)"; \
	else \
		echo "[WARN] Homebrew command not available; subsequent installs may fail."; \
	fi

	@echo "[INSTALL] git, just, pipx..."; \
	brew install git just pipx; \
	export PATH="$$HOME/.local/bin:$$PATH"

	@echo "[INSTALL] ansible and inject ansible-lint..."; \
	pipx install ansible; \
	pipx inject ansible ansible-lint
	export PATH="$$HOME/.local/pipx/venvs/ansible/bin:$$PATH"

	@if [ -d .git ]; then \
		if command -v git &> /dev/null; then \
			echo "[SYNC] Updating git submodules..."; \
			git submodule update --init --recursive; \
		else \
			echo "[WARN] Git is not available; skipping submodule update."; \
		fi; \
	else \
		echo "[SKIP] No git repository detected; skipping submodule update."; \
	fi
	@echo "✅ Bootstrap setup complete. You can now run 'make macbook' or 'make mac-mini'."

.PHONY: macbook
macbook: ## Runs the full setup for a MacBook (requires 'base' to be run first)
	@echo "🚀 Handing over to just for MacBook setup..."
	@just common
	@echo "✅ MacBook full setup completed successfully."

.PHONY: mac-mini
mac-mini: ## Runs the full setup for a Mac mini (requires 'base' to be run first)
	@echo "🚀 Handing over to just for Mac mini setup..."
	@just common
	@echo "✅ Mac mini full setup completed successfully."

.PHONY: system-backup
system-backup: ## Backup current macOS system defaults
	@just cmn-backup-system

.PHONY: vscode-extensions-backup
vscode-extensions-backup: ## Backup current VSCode extensions
	@just cmn-backup-vscode-extensions
