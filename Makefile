# Makefile for macOS Environment Setup

# Shell settings: exit on error, undefined variable, or pipe failure
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Define script directory
SCRIPT_DIR := $(CURDIR)/installers/scripts

# Default target
.DEFAULT_GOAL := help

# Help command to display available targets
.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "; OFS=" "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Main setup target
.PHONY: macbook
macbook: brew git vscode ruby python java flutter node ## Run all setup scripts
	@echo "✅ All setup scripts completed successfully."

# Individual setup targets
.PHONY: brew
brew: ## Setup Homebrew and install packages from Brewfile
	@echo "🚀 Running Homebrew setup..."
	@$(SCRIPT_DIR)/homebrew.sh

.PHONY: git
git: ## Configure Git settings
	@echo "🚀 Running Git setup..."
	@$(SCRIPT_DIR)/git.sh

.PHONY: vscode
vscode: ## Setup VS Code settings and extensions
	@echo "🚀 Running VS Code setup..."
	@$(SCRIPT_DIR)/vscode.sh

.PHONY: ruby
ruby: ## Setup Ruby environment with rbenv
	@echo "🚀 Running Ruby setup..."
	@$(SCRIPT_DIR)/ruby.sh

.PHONY: python
python: ## Setup Python environment with pyenv
	@echo "🚀 Running Python setup..."
	@$(SCRIPT_DIR)/python.sh

.PHONY: java
java: ## Setup Java environment
	@echo "🚀 Running Java setup..."
	@$(SCRIPT_DIR)/java.sh

.PHONY: flutter
flutter: ## Setup Flutter environment
	@echo "🚀 Running Flutter setup..."
	@$(SCRIPT_DIR)/flutter.sh

.PHONY: node
node: ## Setup Node.js environment with nvm
	@echo "🚀 Running Node.js setup..."
	@$(SCRIPT_DIR)/node.sh
