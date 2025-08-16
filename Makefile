# Makefile for macOS Environment Setup

# Shell settings: exit on error, undefined variable, or pipe failure
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Define project root and script/config directories
REPO_ROOT := $(CURDIR)
export REPO_ROOT
SCRIPT_DIR := $(REPO_ROOT)/scripts
CONFIG_DIR_COMMON := config/common
CONFIG_DIR_MACBOOK := config/macbook-only
CONFIG_DIR_MAC_MINI := config/mac-mini-only

# Default target
.DEFAULT_GOAL := help

# Help command to display available targets
.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS=":.*## "; OFS=" "} /^[A-Za-z0-9_-]+:.*## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Main setup targets
.PHONY: all
all: sync-common ## Run all setup scripts with common configuration

.PHONY: sync-common
sync-common: ## Synchronize all common tools and configurations
	@echo "🚀 Synchronizing common tools..."
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) git CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) vscode CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) ruby CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) python CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) java CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) flutter CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) node CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) apply-defaults CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@echo "✅ All common setup completed successfully."

.PHONY: macbook-only
macbook-only: ## Run setup for MacBook only configurations
	@echo "🚀 Setting up for MacBook only..."
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_MACBOOK)
	@$(MAKE) link-shell CONFIG_DIR=$(CONFIG_DIR_MACBOOK)
	@echo "✅ MacBook only setup completed successfully."

.PHONY: mac-mini-only
mac-mini-only: ## Run setup for Mac mini only configurations
	@echo "🚀 Setting up for Mac mini only..."
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_MAC_MINI)
	@$(MAKE) link-shell CONFIG_DIR=$(CONFIG_DIR_MAC_MINI)
	@echo "✅ Mac mini only setup completed successfully."

.PHONY: macbook
macbook: sync-common macbook-only ## Setup for MacBook (common + specific)
	@echo "✅ MacBook full setup completed successfully."

.PHONY: mac-mini
mac-mini: sync-common mac-mini-only ## Setup for Mac mini (common + specific)
	@echo "✅ Mac mini full setup completed successfully."

# Individual setup targets
.PHONY: brew
brew: ## Setup Homebrew and install packages from Brewfile
	@echo "🚀 Running Homebrew setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/homebrew.sh" "$(CONFIG_DIR)"

.PHONY: git
git: ## Configure Git settings
	@echo "🚀 Running Git setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/git.sh" "$(CONFIG_DIR)"

.PHONY: vscode
vscode: ## Setup VS Code settings and extensions
	@echo "🚀 Running VS Code setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/vscode.sh" "$(CONFIG_DIR)"

.PHONY: ruby
ruby: ## Setup Ruby environment with rbenv
	@echo "🚀 Running Ruby setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/ruby.sh" "$(CONFIG_DIR)"

.PHONY: python
python: ## Setup Python environment with pyenv
	@$(MAKE) python-platform CONFIG_DIR=$(CONFIG_DIR)
	@$(MAKE) python-tools CONFIG_DIR=$(CONFIG_DIR)
	@echo "✅ Python setup completed successfully."

.PHONY: python-platform
python-platform: ## Setup Python platform (pyenv, python, pipx)
	@echo "🚀 Running Python platform setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python/platform.sh" "$(CONFIG_DIR)"

.PHONY: python-tools
python-tools: ## Install global Python tools
	@echo "🚀 Running Python tools setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python/tools.sh" "$(CONFIG_DIR)"

.PHONY: java
java: ## Setup Java environment
	@echo "🚀 Running Java setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/java.sh" "$(CONFIG_DIR)"

.PHONY: flutter
flutter: ## Setup Flutter environment
	@echo "🚀 Running Flutter setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/flutter.sh" "$(CONFIG_DIR)"

.PHONY: node
node: ## Setup Node.js environment with nvm
	@$(MAKE) node-platform CONFIG_DIR=$(CONFIG_DIR)
	@$(MAKE) node-packages CONFIG_DIR=$(CONFIG_DIR)
	@echo "✅ Node.js setup completed successfully."

.PHONY: node-platform
node-platform: ## Setup Node.js platform (nvm, node)
	@echo "🚀 Running Node.js platform setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/node/platform.sh" "$(CONFIG_DIR)"

.PHONY: node-packages
node-packages: ## Install global Node.js packages
	@echo "🚀 Running Node.js packages setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/node/packages.sh" "$(CONFIG_DIR)"

.PHONY: link-shell
link-shell: ## Create symbolic links for shell configuration files
	@echo "🚀 Creating symbolic links for shell configuration files with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/link-shell.sh" "$(CONFIG_DIR)"

.PHONY: apply-defaults
apply-defaults: ## Apply macOS system defaults
	@echo "🚀 Applying macOS system defaults with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(REPO_ROOT)/system-defaults/apply-system-defaults.sh" "$(CONFIG_DIR)"

.PHONY: backup-defaults
backup-defaults: ## Backup current macOS system defaults
	@echo "🚀 Backing up current macOS system defaults with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(REPO_ROOT)/system-defaults/backup-system-defaults.sh" "$(CONFIG_DIR)"
	@echo "✅ macOS system defaults backup completed."
