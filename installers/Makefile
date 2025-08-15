# Makefile for tool installers

# Shell settings
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# Define script directory
SCRIPT_DIR := $(CURDIR)/scripts

# Default target
.DEFAULT_GOAL := all

# Help command to display available targets
.PHONY: help
help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@echo "Available targets:"
	@awk 'BEGIN {FS=":.*## "; OFS=" "} /^[A-Za-z0-9_-]+:.*## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Main setup target
.PHONY: all
all: ## Run all setup scripts
	@$(MAKE) brew
	@$(MAKE) git
	@$(MAKE) vscode
	@$(MAKE) ruby
	@$(MAKE) python
	@$(MAKE) java
	@$(MAKE) flutter
	@$(MAKE) node
	@echo "✅ All installer scripts completed successfully."

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
