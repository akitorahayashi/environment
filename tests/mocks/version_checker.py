"""Mock VersionCheckerProtocol implementation."""

from __future__ import annotations

from packaging.version import Version

from menv.protocols import VersionCheckerProtocol


class MockVersionChecker(VersionCheckerProtocol):
    """Mock version checker with configurable responses."""

    def __init__(
        self,
        current_version: str = "0.0.0",
        latest_version: str | None = None,
        upgrade_exit_code: int = 0,
    ) -> None:
        self.current_version = current_version
        self.latest_version = latest_version
        self.upgrade_exit_code = upgrade_exit_code
        self.upgrade_calls = 0

    def get_current_version(self) -> str:
        return self.current_version

    def get_latest_version(self) -> str | None:
        return self.latest_version

    def needs_update(self, current: str, latest: str) -> bool:
        try:
            return Version(latest) > Version(current)
        except Exception:
            return False

    def run_pipx_upgrade(self) -> int:
        self.upgrade_calls += 1
        return self.upgrade_exit_code
