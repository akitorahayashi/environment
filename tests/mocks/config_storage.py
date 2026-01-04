"""Mock ConfigStorage implementation."""

from __future__ import annotations

from menv.models.config import MenvConfig, VcsIdentityConfig
from menv.protocols import ConfigStorageProtocol


class MockConfigStorage(ConfigStorageProtocol):
    """In-memory mock configuration storage for testing."""

    def __init__(self, config: MenvConfig | None = None) -> None:
        self._config = config
        self._config_path = "/mock/config/path/config.toml"

    def exists(self) -> bool:
        return self._config is not None

    def load(self) -> MenvConfig | None:
        return self._config

    def save(self, config: MenvConfig) -> None:
        self._config = config

    def get_identity(self, profile: str) -> VcsIdentityConfig | None:
        if self._config is None:
            return None

        if profile not in ("personal", "work"):
            return None

        return self._config[profile]  # type: ignore[literal-required]

    def get_config_path(self) -> str:
        return self._config_path
