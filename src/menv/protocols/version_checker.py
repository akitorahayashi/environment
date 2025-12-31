"""Protocol for version checking and self-update."""

from __future__ import annotations

from typing import Protocol


class VersionCheckerProtocol(Protocol):
    """Version checking abstraction."""

    def get_current_version(self) -> str:
        """Get the currently installed version of menv."""
        ...

    def get_latest_version(self) -> str | None:
        """Fetch the latest release version."""
        ...

    def needs_update(self, current: str, latest: str) -> bool:
        """Return True when an update is available."""
        ...

    def run_pipx_upgrade(self) -> int:
        """Upgrade menv via pipx and return the exit code."""
        ...
