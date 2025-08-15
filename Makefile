# Makefile for macOS Environment Setup

# Shell settings: exit on error, undefined variable, or pipe failure
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Define script directory
SCRIPT_DIR := $(CURDIR)/installers/scripts
MACOS_SCRIPT_DIR := $(CURDIR)/macos/scripts

# Default target
.DEFAULT_GOAL := help

# Help command to display available targets
.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS=":.*## "; OFS=" "} /^[A-Za-z0-9_-]+:.*## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Main setup target
.PHONY: macbook
macbook: ## Run all setup scripts including macOS configuration
	@$(MAKE) brew
	@$(MAKE) git
	@$(MAKE) vscode
	@$(MAKE) ruby
	@$(MAKE) python
	@$(MAKE) java
	@$(MAKE) flutter
	@$(MAKE) node
	@$(MAKE) link-shell
	@$(MAKE) apply-defaults
	@echo "✅ All setup scripts completed successfully."

# Individual setup targets
.PHONY: brew
brew: ## Setup Homebrew and install packages from Brewfile
	@echo "🚀 Running Homebrew setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/homebrew.sh"

.PHONY: git
git: ## Configure Git settings
	@echo "🚀 Running Git setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/git.sh"

.PHONY: vscode
vscode: ## Setup VS Code settings and extensions
	@echo "🚀 Running VS Code setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/vscode.sh"

.PHONY: ruby
ruby: ## Setup Ruby environment with rbenv
	@echo "🚀 Running Ruby setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/ruby.sh"

.PHONY: python
python: ## Setup Python environment with pyenv
	@echo "🚀 Running Python setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/python.sh"

.PHONY: java
java: ## Setup Java environment
	@echo "🚀 Running Java setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/java.sh"

.PHONY: flutter
flutter: ## Setup Flutter environment
	@echo "🚀 Running Flutter setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/flutter.sh"

.PHONY: node
node: ## Setup Node.js environment with nvm
	@echo "🚀 Running Node.js setup..."
	@$(SHELL) -euo pipefail "$(SCRIPT_DIR)/node.sh"

# macOS-specific targets
.PHONY: link-shell
link-shell: ## Create symbolic links for shell configuration files
	@echo "🚀 Creating symbolic links for shell configuration files..."
	@$(SHELL) -euo pipefail "$(MACOS_SCRIPT_DIR)/link-shell.sh"

.PHONY: apply-defaults
apply-defaults: ## Apply macOS system defaults
	@echo "🚀 Applying macOS system defaults..."
	@$(SHELL) -euo pipefail "$(MACOS_SCRIPT_DIR)/apply-system-defaults.sh"

.PHONY: backup-defaults
backup-defaults: ## Backup current macOS settings
	@echo "🚀 Backing up current macOS settings..."
	@$(SHELL) -euo pipefail "$(MACOS_SCRIPT_DIR)/backup-system-defaults.sh"
	@echo "✅ macOS settings backup completed."
