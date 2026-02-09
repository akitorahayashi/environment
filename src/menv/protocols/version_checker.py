"""Protocol for version checking and self-update."""

from __future__ import annotations

from typing import Protocol


class VersionCheckerProtocol(Protocol):
    """Version checking abstraction."""

    def get_current_version(self) -> str:
        """Get the currently installed version of menv.

        Raises:
            VersionCheckError: If version cannot be determined.
        """
        ...

    def get_latest_version(self) -> str:
        """Fetch the latest release version.

        Raises:
            VersionCheckError: If latest version cannot be fetched.
        """
        ...

    def needs_update(self, current: str, latest: str) -> bool:
        """Return True when an update is available."""
        ...

    def run_pipx_upgrade(self) -> None:
        """Upgrade menv via pipx.

        Raises:
            VersionCheckError: If upgrade fails.
        """
        ...
