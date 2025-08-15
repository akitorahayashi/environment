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

# Main setup targets
# The details of tool installation are delegated to the Makefile in the 'installers' directory.

.PHONY: sync-common
sync-common: ## Synchronize all common tools and configurations
	@echo "🚀 Synchronizing common tools..."
	@$(MAKE) -C installers all

.PHONY: macbook
macbook: ## Setup for MacBook
	@echo "🚀 Setting up for MacBook..."
	@$(MAKE) -C installers all
	@$(MAKE) link-shell
	@$(MAKE) apply-defaults
	@echo "✅ MacBook setup completed successfully."

.PHONY: mac-mini
mac-mini: ## Setup for Mac mini
	@echo "🚀 Setting up for Mac mini..."
	@$(MAKE) -C installers all
	@$(MAKE) link-shell
	@$(MAKE) apply-defaults
	@echo "✅ Mac mini setup completed successfully."

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
backup-defaults: ## Backup current macOS system defaults
	@echo "🚀 Backing up current macOS system defaults..."
	@$(SHELL) -euo pipefail "$(MACOS_SCRIPT_DIR)/backup-system-defaults.sh"
	@echo "✅ macOS system defaults backup completed."
