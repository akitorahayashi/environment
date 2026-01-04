"""Configuration storage protocol definition."""

from __future__ import annotations

from typing import TYPE_CHECKING, Protocol

if TYPE_CHECKING:
    from menv.models.config import MenvConfig, VcsIdentityConfig


class ConfigStorageProtocol(Protocol):
    """Configuration storage abstraction."""

    def exists(self) -> bool:
        """Check if configuration file exists.

        Returns:
            True if config file exists.
        """
        ...

    def load(self) -> MenvConfig | None:
        """Load configuration from storage.

        Returns:
            Configuration dict or None if not found.
        """
        ...

    def save(self, config: MenvConfig) -> None:
        """Save configuration to storage.

        Args:
            config: Configuration to save.
        """
        ...

    def get_identity(self, profile: str) -> VcsIdentityConfig | None:
        """Get identity configuration for a profile.

        Args:
            profile: Profile name ('personal' or 'work').

        Returns:
            Identity configuration or None if not found.
        """
        ...

    def get_config_path(self) -> str:
        """Get the configuration file path as string.

        Returns:
            Path to config file.
        """
        ...
