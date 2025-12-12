# Makefile: The entrypoint for initial environment setup.
#
# This Makefile has several steps for initial setup:
# 1. `make brew`: Installs Homebrew and sets up .env (Requires Terminal Restart)
# 2. `make python`: Installs Pyenv, Python 3.12, Pipx (Requires Terminal Restart)
# 3. `make tools`: Installs uv, ansible, just
# 4. `make macbook` or `make mac-mini`: Runs the actual setup using Just.

.DEFAULT_GOAL := help

.PHONY: help 
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[^_][a-zA-Z0-9_-]*:.*?## / {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- Step 1: Homebrew & Env ---
.PHONY: brew
brew: ## Install Homebrew and setup .env (Requires Terminal Restart)
	@echo "🚀 [Step 1] Setting up Homebrew..."
	@if command -v xcode-select &> /dev/null; then \
		if ! xcode-select -p &> /dev/null; then \
			echo "❌ Xcode Command Line Tools not found. Please run 'xcode-select --install' first."; \
			exit 1; \
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
		echo "[INFO] Executing the Homebrew install script..."; \
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
		echo "⚠️  Please restart your terminal to activate Homebrew."; \
	else \
		echo "[SUCCESS] Homebrew is already installed."; \
	fi

# --- Step 2: Python Runtime ---
.PHONY: python
python: ## Install Pyenv, Python 3.12, Pipx (Requires Terminal Restart)
	@echo "🚀 [Step 2] Setting up Python Environment..."

	@if command -v brew &> /dev/null; then \
		eval "$$(brew shellenv)"; \
	else \
		echo "[WARN] Homebrew command not available; subsequent installs may fail."; \
	fi

	@echo "[INSTALL] pyenv..."; \
	if ! command -v pyenv &> /dev/null; then \
		brew install pyenv; \
	else \
		echo "[SUCCESS] pyenv is already installed."; \
	fi

	@echo "[INSTALL] Python 3.12.11 via pyenv..."; \
	if ! pyenv versions | grep -q '3.12.11'; then \
		pyenv install 3.12.11; \
	else \
		echo "[SUCCESS] Python 3.12.11 is already installed."; \
	fi; \
	pyenv global 3.12.11

	@echo "[INSTALL] pipx..."; \
	eval "$$(pyenv init -)"; \
	if ! command -v pipx &> /dev/null; then \
		python -m pip install --user pipx; \
		python -m pipx ensurepath; \
	else \
		echo "[SUCCESS] pipx is already installed."; \
	fi
	@echo "⚠️  Please restart your terminal to activate pipx."

# --- Step 3: Dev Tools ---
.PHONY: tools
tools: ## Install uv, ansible, just
	@echo "🚀 [Step 3] Installing Dev Tools..."

	@echo "[INSTALL] uv..."; \
	export PATH="$$HOME/.local/bin:$$PATH"; \
	if ! command -v uv &> /dev/null; then \
		pipx install uv; \
	else \
		echo "[SUCCESS] uv is already installed."; \
	fi

	@echo "[INSTALL] Ansible and development tools via uv..."; \
	eval "$$(pyenv init -)"; \
	uv sync

	@echo "[INSTALL] just..."; \
	if ! command -v just &> /dev/null; then \
		brew install just; \
	else \
		echo "[SUCCESS] just is already installed."; \
	fi

	@echo "✅ Ready to run 'make macbook' or 'make mac-mini'!"

.PHONY: macbook
macbook: ## Runs the full setup for a MacBook (requires setup steps 1-3 to be run first)
	@echo "🚀 Handing over to just for MacBook setup..."
	@just common
	@echo "✅ MacBook full setup completed successfully."

.PHONY: mac-mini
mac-mini: ## Runs the full setup for a Mac mini (requires setup steps 1-3 to be run first)
	@echo "🚀 Handing over to just for Mac mini setup..."
	@just common
	@echo "✅ Mac mini full setup completed successfully."

.PHONY: system-backup
system-backup: ## Backup current macOS system defaults
	@just backup-system

.PHONY: vscode-extensions-backup
vscode-extensions-backup: ## Backup current VSCode extensions
	@just backup-vscode-extensions
