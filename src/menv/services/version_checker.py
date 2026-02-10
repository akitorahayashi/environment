"""Version management for menv CLI."""

from __future__ import annotations

import subprocess
from importlib import metadata

import httpx
from packaging.version import Version
from rich.console import Console

from menv.exceptions import VersionCheckError
from menv.protocols.version_checker import VersionCheckerProtocol

GITHUB_REPO = "akitorahayashi/menv"
GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"


class VersionChecker(VersionCheckerProtocol):
    """Check for new releases and upgrade via pipx."""

    def __init__(self, console: Console | None = None) -> None:
        self._console = console or Console()

    def get_current_version(self) -> str:
        """Get the currently installed version of menv."""
        try:
            return metadata.version("menv")
        except metadata.PackageNotFoundError as e:
            raise VersionCheckError("menv package not found") from e

    def get_latest_version(self) -> str:
        """Fetch the latest release version from GitHub."""
        try:
            response = httpx.get(
                GITHUB_API_URL,
                headers={"Accept": "application/vnd.github.v3+json"},
                timeout=10.0,
            )
            response.raise_for_status()
            data = response.json()
            tag = data.get("tag_name", "")
            if not tag:
                raise VersionCheckError("No tag name found in release data")
            return tag.lstrip("v")
        except httpx.HTTPError as e:
            raise VersionCheckError(f"Failed to fetch latest version: {e}") from e
        except (KeyError, ValueError) as e:
            raise VersionCheckError(f"Failed to parse release data: {e}") from e

    def needs_update(self, current: str, latest: str) -> bool:
        """Return True if latest > current."""
        try:
            return Version(latest) > Version(current)
        except (ValueError, TypeError) as e:
            raise VersionCheckError(
                f"Invalid version comparison: {current} vs {latest}"
            ) from e

    def run_pipx_upgrade(self) -> None:
        """Run pipx upgrade menv."""
        self._console.print("[bold blue]Upgrading menv via pipx...[/]")
        try:
            result = subprocess.run(
                ["pipx", "upgrade", "menv"],
                check=False,
            )
            if result.returncode != 0:
                raise VersionCheckError(
                    f"pipx upgrade failed with exit code {result.returncode}"
                )
        except FileNotFoundError as e:
            self._console.print(
                "[bold red]Error:[/] pipx not found. Please ensure pipx is installed."
            )
            raise VersionCheckError("pipx not found") from e
        except OSError as e:
            self._console.print(f"[bold red]Error:[/] Failed to run pipx: {e}")
            raise VersionCheckError(f"Failed to run pipx: {e}") from e
