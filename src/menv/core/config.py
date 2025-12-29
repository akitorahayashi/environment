"""Configuration management for menv."""

from __future__ import annotations

import tomllib
from pathlib import Path
from typing import TypedDict


class IdentityConfig(TypedDict):
    """Identity configuration for VCS."""

    name: str
    email: str


class MenvConfig(TypedDict):
    """Full menv configuration."""

    personal: IdentityConfig
    work: IdentityConfig


def get_config_dir() -> Path:
    """Get the configuration directory path.

    Returns:
        Path to ~/.config/menv/
    """
    return Path.home() / ".config" / "menv"


def get_config_path() -> Path:
    """Get the configuration file path.

    Returns:
        Path to ~/.config/menv/config.toml
    """
    return get_config_dir() / "config.toml"


def config_exists() -> bool:
    """Check if configuration file exists.

    Returns:
        True if config file exists.
    """
    return get_config_path().exists()


def load_config() -> MenvConfig | None:
    """Load configuration from file.

    Returns:
        Configuration dict or None if not found.
    """
    config_path = get_config_path()
    if not config_path.exists():
        return None

    with open(config_path, "rb") as f:
        data = tomllib.load(f)

    return MenvConfig(
        personal=IdentityConfig(
            name=data.get("personal", {}).get("name", ""),
            email=data.get("personal", {}).get("email", ""),
        ),
        work=IdentityConfig(
            name=data.get("work", {}).get("name", ""),
            email=data.get("work", {}).get("email", ""),
        ),
    )


def save_config(config: MenvConfig) -> None:
    """Save configuration to file.

    Args:
        config: Configuration to save.
    """
    config_dir = get_config_dir()
    config_dir.mkdir(parents=True, exist_ok=True)

    config_path = get_config_path()

    # Write TOML manually (simple format, no need for external library)
    lines = [
        "[personal]",
        f'name = "{config["personal"]["name"]}"',
        f'email = "{config["personal"]["email"]}"',
        "",
        "[work]",
        f'name = "{config["work"]["name"]}"',
        f'email = "{config["work"]["email"]}"',
        "",
    ]

    config_path.write_text("\n".join(lines))


def get_identity(profile: str) -> IdentityConfig | None:
    """Get identity configuration for a profile.

    Args:
        profile: Profile name ('personal' or 'work').

    Returns:
        Identity configuration or None if not found.
    """
    config = load_config()
    if config is None:
        return None

    if profile not in ("personal", "work"):
        return None

    return config[profile]  # type: ignore[literal-required]
