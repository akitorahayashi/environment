"""Version management for menv CLI."""

from __future__ import annotations

import subprocess
from importlib import metadata

import httpx
from packaging.version import Version
from rich.console import Console

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
        except metadata.PackageNotFoundError:
            return "0.0.0"

    def get_latest_version(self) -> str | None:
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
            return tag.lstrip("v") if tag else None
        except (httpx.HTTPError, KeyError, ValueError):
            return None

    def needs_update(self, current: str, latest: str) -> bool:
        """Return True if latest > current."""
        try:
            return Version(latest) > Version(current)
        except (ValueError, TypeError):
            return False

    def run_pipx_upgrade(self) -> int:
        """Run pipx upgrade menv."""
        self._console.print("[bold blue]Upgrading menv via pipx...[/]")
        try:
            result = subprocess.run(
                ["pipx", "upgrade", "menv"],
                check=False,
            )
            return result.returncode
        except FileNotFoundError:
            self._console.print(
                "[bold red]Error:[/] pipx not found. Please ensure pipx is installed."
            )
            return 1
        except OSError as e:
            self._console.print(f"[bold red]Error:[/] Failed to run pipx: {e}")
            return 1
