"""Switch command for VCS identity switching."""

from __future__ import annotations

import shutil
import subprocess

import typer
from rich.console import Console

from menv.core.config import config_exists, get_identity

console = Console()

# Profile aliases
PROFILE_ALIASES = {
    "p": "personal",
    "personal": "personal",
    "w": "work",
    "work": "work",
}


def run_git_config(key: str, value: str) -> bool:
    """Set a git global config value.

    Args:
        key: Config key.
        value: Config value.

    Returns:
        True if successful.
    """
    try:
        subprocess.run(
            ["git", "config", "--global", key, value],
            check=True,
            capture_output=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def run_jj_config(key: str, value: str) -> bool:
    """Set a jj (Jujutsu) config value.

    Args:
        key: Config key.
        value: Config value.

    Returns:
        True if successful.
    """
    if not shutil.which("jj"):
        return True  # Skip if jj not installed

    try:
        subprocess.run(
            ["jj", "config", "set", "--user", key, value],
            check=True,
            capture_output=True,
        )
        return True
    except subprocess.CalledProcessError:
        return False


def get_current_git_user() -> tuple[str, str]:
    """Get current git user configuration.

    Returns:
        Tuple of (name, email).
    """
    try:
        name = subprocess.run(
            ["git", "config", "--global", "user.name"],
            capture_output=True,
            text=True,
        ).stdout.strip()
        email = subprocess.run(
            ["git", "config", "--global", "user.email"],
            capture_output=True,
            text=True,
        ).stdout.strip()
        return name, email
    except subprocess.CalledProcessError:
        return "", ""


def switch(
    profile: str = typer.Argument(
        ...,
        help="Profile to switch to (personal/p, work/w).",
    ),
) -> None:
    """Switch VCS identity between personal and work.

    This updates both Git and Jujutsu (jj) user configuration.

    Examples:
        menv switch personal    # Switch to personal identity
        menv switch work        # Switch to work identity
        menv sw p               # Shorthand for personal
        menv sw w               # Shorthand for work
    """
    # Check if config exists
    if not config_exists():
        console.print("[red]Error:[/] No configuration found.")
        console.print("Run [cyan]menv config set[/] first to configure identities.")
        raise typer.Exit(code=1)

    # Resolve profile alias
    resolved_profile = PROFILE_ALIASES.get(profile.lower())
    if resolved_profile is None:
        console.print(f"[red]Error:[/] Invalid profile '{profile}'.")
        console.print("Valid profiles: personal (p), work (w)")
        raise typer.Exit(code=1)

    # Get identity configuration
    identity = get_identity(resolved_profile)
    if identity is None:
        console.print(f"[red]Error:[/] Failed to load {resolved_profile} identity.")
        raise typer.Exit(code=1)

    if not identity["name"] or not identity["email"]:
        console.print(
            f"[red]Error:[/] {resolved_profile.capitalize()} identity is not configured."
        )
        console.print("Run [cyan]menv config set[/] to configure.")
        raise typer.Exit(code=1)

    # Apply configuration
    console.print(f"[blue]Switching to {resolved_profile} identity...[/]")

    # Git configuration
    git_success = True
    git_success &= run_git_config("user.name", identity["name"])
    git_success &= run_git_config("user.email", identity["email"])

    if not git_success:
        console.print("[red]Error:[/] Failed to set Git configuration.")
        raise typer.Exit(code=1)

    # Jujutsu configuration
    jj_success = True
    jj_success &= run_jj_config("user.name", identity["name"])
    jj_success &= run_jj_config("user.email", identity["email"])

    if not jj_success:
        console.print("[yellow]Warning:[/] Failed to set Jujutsu configuration.")

    # Show current configuration
    console.print()
    name, email = get_current_git_user()
    console.print(f"[green]Switched to {resolved_profile} identity[/]")
    console.print(f"  Name:  {name}")
    console.print(f"  Email: {email}")
