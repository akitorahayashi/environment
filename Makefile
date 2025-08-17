# ==============================================================================
# Makefile for macOS Environment Setup
# ==============================================================================

# ------------------------------------------------------------------------------
# Shell and Environment Configuration
# ------------------------------------------------------------------------------
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

REPO_ROOT := $(CURDIR)
export REPO_ROOT
SCRIPT_DIR := $(REPO_ROOT)/scripts
CONFIG_DIR_COMMON := config/common
CONFIG_DIR_MACBOOK := config/macbook-only
CONFIG_DIR_MAC_MINI := config/mac-mini-only

# ------------------------------------------------------------------------------
# User-Facing Commands
# ------------------------------------------------------------------------------
.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS=":.*## ";} /^[a-zA-Z0-9_-]+:.*##/ && !/## @/ {printf "%-25s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- Main Setup Targets ---
.PHONY: macbook
macbook: macbook-brew macbook-git macbook-vscode macbook-ruby macbook-python macbook-java macbook-flutter macbook-node macbook-shell macbook-defaults ## Setup for MacBook (common + specific)
	@echo "✅ MacBook full setup completed successfully."

.PHONY: mac-mini
mac-mini: mac-mini-brew mac-mini-git mac-mini-vscode mac-mini-ruby mac-mini-python mac-mini-java mac-mini-flutter mac-mini-node mac-mini-shell mac-mini-defaults ## Setup for Mac mini (common + specific)
	@echo "✅ Mac mini full setup completed successfully."

# --- Individual Setup Targets for MacBook ---
.PHONY: macbook-brew
macbook-brew: ## [MacBook] Setup Homebrew and install packages
	@echo "🚀 [MacBook] Running Homebrew setup..."
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_MACBOOK)

.PHONY: macbook-git
macbook-git: ## [MacBook] Configure Git settings
	@echo "🚀 [MacBook] Running Git setup..."
	@$(MAKE) git CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-vscode
macbook-vscode: ## [MacBook] Setup VS Code settings and extensions
	@echo "🚀 [MacBook] Running VS Code setup..."
	@$(MAKE) vscode CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-ruby
macbook-ruby: ## [MacBook] Setup Ruby environment with rbenv
	@echo "🚀 [MacBook] Running Ruby setup..."
	@$(MAKE) ruby CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-python
macbook-python: ## [MacBook] Setup Python environment with pyenv
	@echo "🚀 [MacBook] Running Python setup..."
	@$(MAKE) python CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-java
macbook-java: ## [MacBook] Setup Java environment
	@echo "🚀 [MacBook] Running Java setup..."
	@$(MAKE) java CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-flutter
macbook-flutter: ## [MacBook] Setup Flutter environment
	@echo "🚀 [MacBook] Running Flutter setup..."
	@$(MAKE) flutter CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-node
macbook-node: ## [MacBook] Setup Node.js environment with nvm
	@echo "🚀 [MacBook] Running Node.js setup..."
	@$(MAKE) node CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: macbook-shell
macbook-shell: ## [MacBook] Link shell configuration files
	@echo "🚀 [MacBook] Linking shell configuration..."
	@$(MAKE) link-shell CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) link-shell CONFIG_DIR=$(CONFIG_DIR_MACBOOK)

.PHONY: macbook-defaults
macbook-defaults: ## [MacBook] Apply macOS system defaults
	@echo "🚀 [MacBook] Applying system defaults..."
	@$(MAKE) apply-defaults CONFIG_DIR=$(CONFIG_DIR_COMMON)

# --- Individual Setup Targets for Mac mini ---
.PHONY: mac-mini-brew
mac-mini-brew: ## [Mac mini] Setup Homebrew and install packages
	@echo "🚀 [Mac mini] Running Homebrew setup..."
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) brew CONFIG_DIR=$(CONFIG_DIR_MAC_MINI)

.PHONY: mac-mini-git
mac-mini-git: ## [Mac mini] Configure Git settings
	@echo "🚀 [Mac mini] Running Git setup..."
	@$(MAKE) git CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-vscode
mac-mini-vscode: ## [Mac mini] Setup VS Code settings and extensions
	@echo "🚀 [Mac mini] Running VS Code setup..."
	@$(MAKE) vscode CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-ruby
mac-mini-ruby: ## [Mac mini] Setup Ruby environment with rbenv
	@echo "🚀 [Mac mini] Running Ruby setup..."
	@$(MAKE) ruby CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-python
mac-mini-python: ## [Mac mini] Setup Python environment with pyenv
	@echo "🚀 [Mac mini] Running Python setup..."
	@$(MAKE) python CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-java
mac-mini-java: ## [Mac mini] Setup Java environment
	@echo "🚀 [Mac mini] Running Java setup..."
	@$(MAKE) java CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-flutter
mac-mini-flutter: ## [Mac mini] Setup Flutter environment
	@echo "🚀 [Mac mini] Running Flutter setup..."
	@$(MAKE) flutter CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-node
mac-mini-node: ## [Mac mini] Setup Node.js environment with nvm
	@echo "🚀 [Mac mini] Running Node.js setup..."
	@$(MAKE) node CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mac-mini-shell
mac-mini-shell: ## [Mac mini] Link shell configuration files
	@echo "🚀 [Mac mini] Linking shell configuration..."
	@$(MAKE) link-shell CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) link-shell CONFIG_DIR=$(CONFIG_DIR_MAC_MINI)

.PHONY: mac-mini-defaults
mac-mini-defaults: ## [Mac mini] Apply macOS system defaults
	@echo "🚀 [Mac mini] Applying system defaults..."
	@$(MAKE) apply-defaults CONFIG_DIR=$(CONFIG_DIR_COMMON)

# --- Other User-Facing Commands ---
.PHONY: backup-defaults
backup-defaults: ## Backup current macOS system defaults
	@echo "🚀 Backing up current macOS system defaults..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/system-defaults/backup-system-defaults.sh" "config/common"
	@echo "✅ macOS system defaults backup completed."

# ------------------------------------------------------------------------------
# Internal (Hidden) Commands - Do not run directly
# ------------------------------------------------------------------------------
.PHONY: brew
brew: ## @hidden
	@echo "  -> Running Homebrew setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/homebrew.sh" "$(CONFIG_DIR)"

.PHONY: git
git: ## @hidden
	@echo "  -> Running Git setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/git.sh" "$(CONFIG_DIR)"

.PHONY: vscode
vscode: ## @hidden
	@echo "  -> Running VS Code setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/vscode.sh" "$(CONFIG_DIR)"

.PHONY: ruby
ruby: ## @hidden
	@echo "  -> Running Ruby setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/ruby.sh" "$(CONFIG_DIR)"

.PHONY: python
python: python-platform python-tools ## @hidden
	@echo "  -> Python setup completed for config: $(CONFIG_DIR)"

.PHONY: python-platform
python-platform: ## @hidden
	@echo "  -> Running Python platform setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python/platform.sh" "$(CONFIG_DIR)"

.PHONY: python-tools
python-tools: ## @hidden
	@echo "  -> Running Python tools setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python/tools.sh" "$(CONFIG_DIR)"

.PHONY: java
java: ## @hidden
	@echo "  -> Running Java setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/java.sh" "$(CONFIG_DIR)"

.PHONY: flutter
flutter: ## @hidden
	@echo "  -> Running Flutter setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/flutter.sh" "$(CONFIG_DIR)"

.PHONY: node
node: node-platform node-packages ## @hidden
	@echo "  -> Node.js setup completed for config: $(CONFIG_DIR)"

.PHONY: node-platform
node-platform: ## @hidden
	@echo "  -> Running Node.js platform setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/node/platform.sh" "$(CONFIG_DIR)"

.PHONY: node-packages
node-packages: ## @hidden
	@echo "  -> Running Node.js packages setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/node/packages.sh" "$(CONFIG_DIR)"

.PHONY: link-shell
link-shell: ## @hidden
	@echo "  -> Linking shell configuration files from: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/link-shell.sh" "$(CONFIG_DIR)"

.PHONY: apply-defaults
apply-defaults: ## @hidden
	@echo "  -> Applying macOS system defaults from: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/system-defaults/apply-system-defaults.sh" "$(CONFIG_DIR)"
