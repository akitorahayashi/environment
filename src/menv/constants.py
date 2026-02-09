"""Application constants and domain definitions."""

from typing import Final

# Profiles
PROFILE_COMMON: Final = "common"
PROFILE_MACBOOK: Final = "macbook"
PROFILE_MAC_MINI: Final = "mac-mini"

# Collections of profiles
# Used in 'make' command (allows running tasks on any profile including common)
VALID_PROFILES: Final = {PROFILE_COMMON, PROFILE_MACBOOK, PROFILE_MAC_MINI}

# Used in 'create' command (requires a specific machine profile)
MACHINE_PROFILES: Final = {PROFILE_MACBOOK, PROFILE_MAC_MINI}

# Aliases
PROFILE_ALIASES: Final = {
    "mmn": PROFILE_MAC_MINI,
    "mbk": PROFILE_MACBOOK,
    "cmn": PROFILE_COMMON,
}

# Tag Groups (for 'make' command)
TAG_GROUPS: Final = {
    "rust": ["rust-platform", "rust-tools"],
    "python": ["python-platform", "python-tools"],
    "nodejs": ["nodejs-platform", "nodejs-tools"],
    "go": ["go-platform", "go-tools"],
}

# Full Setup Tags (for 'create' command)
FULL_SETUP_TAGS: Final = [
    # Phase 0: Brew dependencies (must be first)
    "brew-formulae",
    "ollama",
    # Phase 1: Configuration
    "shell",
    "system",
    "git",
    "jj",
    "gh",
    # Phase 2: Language runtimes
    "python-platform",
    "nodejs-platform",
    "ruby",
    "rust-platform",
    "go-platform",
    # Phase 3: Language tools (require runtimes)
    "python-tools",
    "uv",
    "nodejs-tools",
    "rust-tools",
    "go-tools",
    # Phase 4: Editors
    "vscode",
    "cursor",
    # Phase 5: Additional tools
    "aider",
    "coder",
    "mlx",
    "xcode",
]
