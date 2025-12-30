"""Config command for managing menv settings."""

from __future__ import annotations

from typing import TYPE_CHECKING

import typer
from rich.console import Console
from rich.table import Table

from menv.storage.types import IdentityConfig, MenvConfig

if TYPE_CHECKING:
    from menv.context import AppContext

console = Console()


def show_config(ctx: typer.Context) -> None:
    """Display current configuration."""
    app_ctx: AppContext = ctx.obj

    if not app_ctx.config_storage.exists():
        console.print("[yellow]No configuration found.[/]")
        console.print("Run [cyan]menv config set[/] to configure.")
        raise typer.Exit(code=1)

    config = app_ctx.config_storage.load()
    if config is None:
        console.print("[red]Error:[/] Failed to load configuration.")
        raise typer.Exit(code=1)

    console.print(f"[dim]Config file:[/] {app_ctx.config_storage.get_config_path()}")
    console.print()

    table = Table(show_header=True)
    table.add_column("Profile", style="cyan")
    table.add_column("Name")
    table.add_column("Email")

    table.add_row("personal", config["personal"]["name"], config["personal"]["email"])
    table.add_row("work", config["work"]["name"], config["work"]["email"])

    console.print(table)


def set_config(ctx: typer.Context) -> None:
    """Set configuration interactively."""
    app_ctx: AppContext = ctx.obj

    console.print("[bold]Configure menv VCS identities[/]")
    console.print()

    # Load existing config for defaults
    existing = app_ctx.config_storage.load()

    # Personal settings
    console.print("[cyan]Personal identity:[/]")
    personal_name = typer.prompt(
        "  Name",
        default=existing["personal"]["name"] if existing else "",
    )
    personal_email = typer.prompt(
        "  Email",
        default=existing["personal"]["email"] if existing else "",
    )

    console.print()

    # Work settings
    console.print("[cyan]Work identity:[/]")
    work_name = typer.prompt(
        "  Name",
        default=existing["work"]["name"] if existing else "",
    )
    work_email = typer.prompt(
        "  Email",
        default=existing["work"]["email"] if existing else "",
    )

    # Save configuration
    config = MenvConfig(
        personal=IdentityConfig(name=personal_name, email=personal_email),
        work=IdentityConfig(name=work_name, email=work_email),
    )
    app_ctx.config_storage.save(config)

    console.print()
    console.print(
        f"[green]Configuration saved to {app_ctx.config_storage.get_config_path()}[/]"
    )


def config(
    ctx: typer.Context,
    action: str = typer.Argument(
        ...,
        help="Action to perform (set, show).",
    ),
) -> None:
    """Manage menv configuration.

    Examples:
        menv config set             # Configure interactively
        menv config show            # Show current config
        menv cf set                 # Alias
        menv cf show                # Alias
    """
    if action == "set":
        set_config(ctx)
    elif action == "show":
        show_config(ctx)
    else:
        console.print(f"[red]Error:[/] Unknown action '{action}'.")
        console.print("Valid actions: set, show")
        raise typer.Exit(code=1)
