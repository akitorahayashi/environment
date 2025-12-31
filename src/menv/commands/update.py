"""Update command for self-updating menv."""

import typer
from rich.console import Console

from menv.context import AppContext

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

    current = app_ctx.version_checker.get_current_version()
    console.print(f"[dim]Current version:[/] {current}")

    console.print("[dim]Checking for updates...[/]")
    latest = app_ctx.version_checker.get_latest_version()

    if latest is None:
        console.print(
            "[yellow]Could not fetch latest version from GitHub. "
            "Check your network connection.[/]"
        )
        raise typer.Exit(code=1)

    console.print(f"[dim]Latest version:[/]  {latest}")

    if not app_ctx.version_checker.needs_update(current, latest):
        console.print()
        console.print("[bold green]✓ You are already on the latest version![/]")
        return

    console.print()
    console.print(f"[bold blue]Update available:[/] {current} → {latest}")

    exit_code = app_ctx.version_checker.run_pipx_upgrade()

    if exit_code == 0:
        new_version = app_ctx.version_checker.get_current_version()
        console.print()
        console.print(
            f"[bold green]✓ Successfully updated to version {new_version}![/]"
        )
    else:
        console.print()
        console.print(f"[bold red]✗ Update failed with exit code {exit_code}[/]")
        raise typer.Exit(code=exit_code)
