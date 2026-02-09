"""Update command for self-updating menv."""

import typer
from rich.console import Console

from menv.context import AppContext
from menv.exceptions import VersionCheckError

console = Console()


def update(ctx: typer.Context) -> None:
    """Check for and install menv updates.

    Fetches the latest version from GitHub and upgrades via pipx if a newer
    version is available.

    Examples:
        menv update
        menv u
    """
    app_ctx: AppContext = ctx.obj

    try:
        current = app_ctx.version_checker.get_current_version()
        console.print(f"[dim]Current version:[/] {current}")

        console.print("[dim]Checking for updates...[/]")
        latest = app_ctx.version_checker.get_latest_version()

        console.print(f"[dim]Latest version:[/]  {latest}")

        if not app_ctx.version_checker.needs_update(current, latest):
            console.print()
            console.print("[bold green]✓ You are already on the latest version![/]")
            return

        console.print()
        console.print(f"[bold blue]Update available:[/] {current} → {latest}")

        app_ctx.version_checker.run_pipx_upgrade()

        new_version = app_ctx.version_checker.get_current_version()
        console.print()
        console.print(
            f"[bold green]✓ Successfully updated to version {new_version}![/]"
        )

    except VersionCheckError as e:
        console.print()
        console.print(f"[bold red]✗ Update failed:[/] {e}")
        raise typer.Exit(code=1)
