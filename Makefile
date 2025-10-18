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
	@awk 'BEGIN {FS = ":.*?## "} /^[^_][a-zA-Z0-9_-]*:.*?## / {printf "  \033[36m%-25s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: base
base: ## Installs pyenv, Python 3.12, uv, and core dependencies
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
		/bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; \
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

	@echo "[CREATE] Creating venv at ./mlx-lm"
	@if [ ! -d "mlx-lm" ]; then \
		uv venv mlx-lm; \
	else \
		echo "[INFO] ./mlx-lm already exists."; \
	fi

	@echo "[INSTALL] Installing mlx dependency-group into ./mlx-lm"
	UV_PROJECT_ENVIRONMENT=./mlx-lm uv sync --only-group mlx
	@echo "✅ mlx-lm venv prepared."

	@echo "[INSTALL] just..."; \
	if ! command -v just &> /dev/null; then \
		brew install just; \
	else \
		echo "[SUCCESS] just is already installed."; \
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
