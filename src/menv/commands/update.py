"""Update command for self-updating menv."""

import typer
from rich.console import Console

from menv.version import (
    get_current_version,
    get_latest_version,
    needs_update,
    run_pipx_upgrade,
)

console = Console()


def update() -> None:
    """Check for and install menv updates.

    Fetches the latest version from GitHub and upgrades via pipx if a newer
    version is available.

    Examples:
        menv update
        menv u
    """
    current = get_current_version()
    console.print(f"[dim]Current version:[/] {current}")

    console.print("[dim]Checking for updates...[/]")
    latest = get_latest_version()

    if latest is None:
        console.print(
            "[yellow]Could not fetch latest version from GitHub. "
            "Check your network connection.[/]"
        )
        raise typer.Exit(code=1)

    console.print(f"[dim]Latest version:[/]  {latest}")

    if not needs_update(current, latest):
        console.print()
        console.print("[bold green]✓ You are already on the latest version![/]")
        return

    console.print()
    console.print(f"[bold blue]Update available:[/] {current} → {latest}")

    exit_code = run_pipx_upgrade()

    if exit_code == 0:
        new_version = get_current_version()
        console.print()
        console.print(
            f"[bold green]✓ Successfully updated to version {new_version}![/]"
        )
    else:
        console.print()
        console.print(f"[bold red]✗ Update failed with exit code {exit_code}[/]")
        raise typer.Exit(code=exit_code)
