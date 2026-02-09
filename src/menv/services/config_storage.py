"""Filesystem-based configuration storage implementation."""

from __future__ import annotations

import tomllib
from pathlib import Path

import tomli_w

from menv.models.config import MenvConfig, VcsIdentityConfig, validate_config
from menv.protocols.config_storage import ConfigStorageProtocol


class ConfigStorage(ConfigStorageProtocol):
    """Filesystem-based configuration storage."""

    def __init__(self, config_dir: Path | None = None) -> None:
        """Initialize filesystem config storage.

        Args:
            config_dir: Configuration directory path.
                        Defaults to ~/.config/menv
        """
        if config_dir is None:
            config_dir = Path.home() / ".config" / "menv"
        self._config_dir = config_dir
        self._config_path = config_dir / "config.toml"

    def exists(self) -> bool:
        """Check if configuration file exists.

        Returns:
            True if config file exists.
        """
        return self._config_path.exists()

    def load(self) -> MenvConfig | None:
        """Load configuration from file.

        Returns:
            Configuration dict or None if not found.
        """
        if not self._config_path.exists():
            return None

        with open(self._config_path, "rb") as f:
            data = tomllib.load(f)

        return validate_config(data)

    def save(self, config: MenvConfig) -> None:
        """Save configuration to file.

        Args:
            config: Configuration to save.
        """
        validate_config(config)

        self._config_dir.mkdir(parents=True, exist_ok=True)

        with open(self._config_path, "wb") as f:
            tomli_w.dump(config, f)

    def get_identity(self, profile: str) -> VcsIdentityConfig | None:
        """Get identity configuration for a profile.

        Args:
            profile: Profile name ('personal' or 'work').

        Returns:
            Identity configuration or None if not found.
        """
        config = self.load()
        if config is None:
            return None

        if profile not in ("personal", "work"):
            return None

        return config[profile]  # type: ignore[literal-required]

    def get_config_path(self) -> str:
        """Get the configuration file path as string.

        Returns:
            Path to config file.
        """
        return str(self._config_path)
