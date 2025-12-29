"""Config command for managing menv settings."""

from __future__ import annotations

import typer
from rich.console import Console
from rich.table import Table

from menv.core.config import (
    IdentityConfig,
    MenvConfig,
    config_exists,
    get_config_path,
    load_config,
    save_config,
)

console = Console()


def show_config() -> None:
    """Display current configuration."""
    if not config_exists():
        console.print("[yellow]No configuration found.[/]")
        console.print("Run [cyan]menv config set[/] to configure.")
        raise typer.Exit(code=1)

    config = load_config()
    if config is None:
        console.print("[red]Error:[/] Failed to load configuration.")
        raise typer.Exit(code=1)

    console.print(f"[dim]Config file:[/] {get_config_path()}")
    console.print()

    table = Table(show_header=True)
    table.add_column("Profile", style="cyan")
    table.add_column("Name")
    table.add_column("Email")

    table.add_row("personal", config["personal"]["name"], config["personal"]["email"])
    table.add_row("work", config["work"]["name"], config["work"]["email"])

    console.print(table)


def set_config() -> None:
    """Set configuration interactively."""
    console.print("[bold]Configure menv VCS identities[/]")
    console.print()

    # Load existing config for defaults
    existing = load_config()

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
    save_config(config)

    console.print()
    console.print(f"[green]Configuration saved to {get_config_path()}[/]")


def config(
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
        set_config()
    elif action == "show":
        show_config()
    else:
        console.print(f"[red]Error:[/] Unknown action '{action}'.")
        console.print("Valid actions: set, show")
        raise typer.Exit(code=1)
