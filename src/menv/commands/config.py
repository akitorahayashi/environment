"""Config command for managing menv settings."""

from __future__ import annotations

from typing import TYPE_CHECKING, Optional

import typer
from rich.console import Console
from rich.table import Table

from menv.models.config import IdentityConfig, MenvConfig

if TYPE_CHECKING:
    from menv.context import AppContext

console = Console()

config_app = typer.Typer(
    name="config",
    help="Manage menv configuration.",
    no_args_is_help=True,
)


@config_app.command(name="show")
def show_config(ctx: typer.Context) -> None:
    """Display current VCS identity configuration."""
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


@config_app.command(name="set")
def set_config(ctx: typer.Context) -> None:
    """Set VCS identity configuration interactively."""
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


@config_app.command(name="create")
def create_config(
    ctx: typer.Context,
    role: Optional[str] = typer.Argument(
        None,
        help="Role name to deploy config for. If omitted, deploys all roles.",
    ),
    overlay: bool = typer.Option(
        False,
        "--overlay",
        "-o",
        help="Overwrite existing config with package defaults.",
    ),
) -> None:
    """Deploy role configs to ~/.config/menv/roles/.

    This copies config files from the menv package to your local config
    directory, allowing you to edit them without reinstalling menv.

    Examples:
        menv config create              # Deploy all role configs
        menv config create rust         # Deploy only rust config
        menv config create --overlay    # Overwrite existing with defaults
        menv cf cr rust -o              # Shorthand with overlay
    """
    app_ctx: AppContext = ctx.obj

    if role:
        # Deploy single role
        result = app_ctx.config_deployer.deploy_role(role, overlay=overlay)
        if result.success:
            console.print(f"[green]✓[/] {result.role}: {result.message}")
        else:
            console.print(f"[red]✗[/] {result.role}: {result.message}")
            raise typer.Exit(code=1)
    else:
        # Deploy all roles
        results = app_ctx.config_deployer.deploy_all(overlay=overlay)
        success_count = 0
        fail_count = 0

        for result in results:
            if result.success:
                console.print(f"[green]✓[/] {result.role}: {result.message}")
                success_count += 1
            else:
                console.print(f"[red]✗[/] {result.role}: {result.message}")
                fail_count += 1

        console.print()
        console.print(
            f"[bold]Deployed {success_count} configs"
            + (f", {fail_count} failed" if fail_count > 0 else "")
            + "[/]"
        )

        if fail_count > 0:
            raise typer.Exit(code=1)


# Alias for create command
config_app.command(name="cr", hidden=True)(create_config)
