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
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[^_][a-zA-Z0-9_-]*:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# --- Main Setup Targets ---
.PHONY: macbook
macbook: ## Setup for MacBook (common + specific)
	@echo "🚀 Starting full MacBook setup..."
	@$(MAKE) common
	@$(MAKE) mbk-brew
	@$(MAKE) mbk-python-tools
	@$(MAKE) mbk-nodejs-tools
	@echo "✅ MacBook full setup completed successfully."

.PHONY: mac-mini
mac-mini: ## Setup for Mac mini (common + specific)
	@echo "🚀 Starting full Mac mini setup..."
	@$(MAKE) mmn-brew
	@$(MAKE) common
	@echo "✅ Mac mini full setup completed successfully."

# --- Common Setup Targets ---
.PHONY: common
common: ## Run all common setup tasks
	@echo "🚀 Starting all common setup tasks..."
	@$(MAKE) git
	@$(MAKE) gh
	@$(MAKE) vscode
	@$(MAKE) ruby
	@$(MAKE) python-platform
	@$(MAKE) python-tools
	@$(MAKE) java
	@$(MAKE) flutter
	@$(MAKE) nodejs-platform
	@$(MAKE) nodejs-tools
	@$(MAKE) shell
	@$(MAKE) apply-defaults
	@echo "✅ All common setup tasks completed successfully."

.PHONY: git
git: ## Configure Git settings (common)
	@echo "🚀 Running common Git setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/git.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: gh
gh: ## Configure GitHub CLI (gh) settings (common)
	@echo "🚀 Running common GitHub CLI setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/gh.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: vscode
vscode: ## Setup VS Code settings and extensions (common)
	@echo "🚀 Running common VS Code setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/vscode.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: ruby
ruby: ## Setup Ruby environment with rbenv (common)
	@echo "🚀 Running common Ruby setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/ruby.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: python-platform
python-platform: ## Setup Python platform (common)
	@echo "🚀 Running common Python platform setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python/platform.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: python-tools
python-tools: ## Install common Python tools (common)
	@echo "🚀 Installing common Python tools..."
	@$(MAKE) _python-tools CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mbk-python-tools
mbk-python-tools: ## Install MacBook-specific Python tools
	@echo "🚀 Installing MacBook-specific Python tools..."
	@$(MAKE) _python-tools CONFIG_DIR=$(CONFIG_DIR_MACBOOK)


.PHONY: java
java: ## Setup Java environment (common)
	@echo "🚀 Running common Java setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/java.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: flutter
flutter: ## Setup Flutter environment (common)
	@echo "🚀 Running common Flutter setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/flutter.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: nodejs-platform
nodejs-platform: ## Setup Node.js platform (common)
	@echo "🚀 Running common Node.js platform setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/nodejs/platform.sh" "$(CONFIG_DIR_COMMON)"

.PHONY: nodejs-tools
nodejs-tools: ## Install common Node.js tools (common)
	@echo "🚀 Installing common Node.js tools..."
	@$(MAKE) _nodejs-tools CONFIG_DIR=$(CONFIG_DIR_COMMON)

.PHONY: mbk-nodejs-tools
mbk-nodejs-tools: ## Install MacBook-specific Node.js tools
	@echo "🚀 Installing MacBook-specific Node.js tools..."
	@$(MAKE) _nodejs-tools CONFIG_DIR=$(CONFIG_DIR_MACBOOK)


.PHONY: apply-defaults
apply-defaults: ## Apply macOS system defaults (common)
	@echo "🚀 Applying common system defaults..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/system-defaults/apply-system-defaults.sh" "$(CONFIG_DIR_COMMON)"

# --- Individual Setup Targets for MacBook ---
.PHONY: mbk-brew
mbk-brew: ## [MacBook] Setup Homebrew and install packages
	@echo "🚀 [MacBook] Running Homebrew setup..."
	@$(MAKE) _brew CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) _brew CONFIG_DIR=$(CONFIG_DIR_MACBOOK)

.PHONY: shell
shell: ## Link common shell configuration files
	@echo "🚀 Linking common shell configuration..."
	@$(MAKE) _link-shell CONFIG_DIR=$(CONFIG_DIR_COMMON)

# --- Individual Setup Targets for Mac mini ---
.PHONY: mmn-brew
mmn-brew: ## [Mac mini] Setup Homebrew and install packages
	@echo "🚀 [Mac mini] Running Homebrew setup..."
	@$(MAKE) _brew CONFIG_DIR=$(CONFIG_DIR_COMMON)
	@$(MAKE) _brew CONFIG_DIR=$(CONFIG_DIR_MAC_MINI)

# --- Other User-Facing Commands ---
.PHONY: backup-defaults
backup-defaults: ## Backup current macOS system defaults
	@echo "🚀 Backing up current macOS system defaults..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/system-defaults/backup-system-defaults.sh" "config/common"
	@echo "✅ macOS system defaults backup completed."

# ------------------------------------------------------------------------------
# Internal Commands
# ------------------------------------------------------------------------------
.PHONY: _brew
_brew: ## @hidden
	@echo "  -> Running Homebrew setup with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/homebrew.sh" "$(CONFIG_DIR)"

.PHONY: _python-tools
_python-tools: ## @hidden
	@echo "  -> Installing python tools with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python/tools.sh" "$(CONFIG_DIR)"

.PHONY: _link-shell
_link-shell: ## @hidden
	@echo "  -> Linking shell configuration files from: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/shell.sh" "$(CONFIG_DIR)"

.PHONY: _nodejs-tools
_nodejs-tools: ## @hidden
	@echo "  -> Installing node tools with config: $(CONFIG_DIR)"
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/nodejs/tools.sh" "$(CONFIG_DIR)"
