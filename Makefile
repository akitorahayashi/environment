# Makefile: The entrypoint for initial environment setup.
#
# This Makefile has two main steps:
# 1. `make setup`: Installs Homebrew and Just.
# 2. `make macbook` or `make mac-mini`: Runs the actual setup using Just.

.DEFAULT_GOAL := help

.PHONY: help 
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[^_][a-zA-Z0-9_-]*:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: setup
setup: ## Installs Homebrew and the 'just' command runner
	@echo "🚀 Starting bootstrap setup..."

	@if [ ! -f .env ]; then \
		cp .env.example .env && \
		echo "📝 Created .env file from .env.example. Please edit GIT_USERNAME and GIT_EMAIL."; \
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
		eval "$('/opt/homebrew/bin/brew' shellenv)"; \
		echo "[SUCCESS] Homebrew のインストール完了"; \
	else \
		echo "[SUCCESS] Homebrew はすでにインストールされています"; \
	fi

	@if ! command -v just &> /dev/null; then \
		echo "    [INSTALL] just..."; \
		brew install just; \
	else \
		echo "[SUCCESS] just is already installed."; \
	fi

	@if ! command -v pipx &> /dev/null; then \
		echo "[INSTALL] pipx..."; \
		brew install pipx; \
		export PATH="$$HOME/.local/bin:$$PATH"; \
	else \
		echo "[SUCCESS] pipx is already installed."; \
	fi

	@if ! command -v ansible &> /dev/null; then \
		echo "[INSTALL] ansible..."; \
		pipx install ansible; \
		export PATH="$$HOME/.local/bin:$$PATH"; \
	else \
		echo "[SUCCESS] ansible is already installed."; \
	fi
	@echo "✅ Bootstrap setup complete. You can now run 'make macbook' or 'make mac-mini'."

.PHONY: macbook
macbook: ## Runs the full setup for a MacBook (requires 'setup' to be run first)
	@echo "🚀 Handing over to just for MacBook setup..."
	@just common
	@just mbk-brew
	@just mbk-nodejs-tools
	@just mbk-python-tools
	@echo "✅ MacBook full setup completed successfully."

.PHONY: mac-mini
mac-mini: ## Runs the full setup for a Mac mini (requires 'setup' to be run first)
	@echo "🚀 Handing over to just for Mac mini setup..."
	@just common
	@just mmn-brew
	@just mmn-nodejs-tools
	@just mmn-python-tools
	@echo "✅ Mac mini full setup completed successfully."

.PHONY: defaults-backup
defaults-backup: ## Backup current macOS system defaults
	@just cmn-backup-defaults

.PHONY: vscode-extensions-backup
vscode-extensions-backup: ## Backup current VSCode extensions
	@just cmn-backup-vscode-extensions