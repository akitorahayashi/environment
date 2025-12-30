"""Mock configuration storage for testing."""

from __future__ import annotations

from menv.storage.types import IdentityConfig, MenvConfig


class MockConfigStorage:
    """In-memory mock configuration storage for testing."""

    def __init__(self, config: MenvConfig | None = None) -> None:
        """Initialize mock storage.

        Args:
            config: Optional initial configuration.
        """
        self._config = config
        self._config_path = "/mock/config/path/config.toml"

    def exists(self) -> bool:
        """Check if configuration exists.

        Returns:
            True if config is set.
        """
        return self._config is not None

    def load(self) -> MenvConfig | None:
        """Load configuration.

        Returns:
            Configuration dict or None if not set.
        """
        return self._config

    def save(self, config: MenvConfig) -> None:
        """Save configuration.

        Args:
            config: Configuration to save.
        """
        self._config = config

    def get_identity(self, profile: str) -> IdentityConfig | None:
        """Get identity configuration for a profile.

        Args:
            profile: Profile name ('personal' or 'work').

        Returns:
            Identity configuration or None if not found.
        """
        if self._config is None:
            return None

        if profile not in ("personal", "work"):
            return None

        return self._config[profile]  # type: ignore[literal-required]

    def get_config_path(self) -> str:
        """Get the configuration file path.

        Returns:
            Mock path string.
        """
        return self._config_path
