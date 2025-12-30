"""Version management for menv CLI."""

from __future__ import annotations

import subprocess
from importlib import metadata

import httpx
from packaging.version import Version
from rich.console import Console

GITHUB_REPO = "akitorahayashi/menv"
GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"

console = Console()


def get_current_version() -> str:
    """Get the currently installed version of menv.

    Returns:
        Version string (e.g., '0.1.0').
    """
    try:
        return metadata.version("menv")
    except metadata.PackageNotFoundError:
        return "0.0.0"


def get_latest_version() -> str | None:
    """Fetch the latest release version from GitHub.

    Returns:
        Latest version string or None if fetch fails.
    """
    try:
        response = httpx.get(
            GITHUB_API_URL,
            headers={"Accept": "application/vnd.github.v3+json"},
            timeout=10.0,
        )
        response.raise_for_status()
        data = response.json()
        tag = data.get("tag_name", "")
        # Remove 'v' prefix if present
        return tag.lstrip("v") if tag else None
    except (httpx.HTTPError, KeyError, ValueError):
        return None


def needs_update(current: str, latest: str) -> bool:
    """Check if an update is available.

    Args:
        current: Current version string.
        latest: Latest version string.

    Returns:
        True if latest > current.
    """
    try:
        return Version(latest) > Version(current)
    except Exception:
        return False


def run_pipx_upgrade() -> int:
    """Run pipx upgrade menv.

    Returns:
        Exit code from pipx.
    """
    console.print("[bold blue]Upgrading menv via pipx...[/]")
    try:
        result = subprocess.run(
            ["pipx", "upgrade", "menv"],
            check=False,
        )
        return result.returncode
    except FileNotFoundError:
        console.print(
            "[bold red]Error:[/] pipx not found. Please ensure pipx is installed."
        )
        return 1
