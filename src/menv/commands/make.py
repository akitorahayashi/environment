"""Make command for running individual Ansible tasks."""

from __future__ import annotations

from typing import TYPE_CHECKING

import typer
from rich.console import Console
from rich.table import Table

from menv.constants import PROFILE_ALIASES, TAG_GROUPS, VALID_PROFILES
from menv.exceptions import AnsibleExecutionError

if TYPE_CHECKING:
    from menv.context import AppContext

console = Console()


def _get_roles_for_tags(app_ctx: AppContext, tags: list[str]) -> set[str]:
    """Get unique role names for a list of tags that have config directories."""
    roles_with_config = set(app_ctx.config_deployer.roles_with_config)
    return {
        role
        for tag in tags
        if (role := app_ctx.playbook.get_role_for_tag(tag))
        and role in roles_with_config
    }


def _deploy_configs_for_roles(
    app_ctx: AppContext, roles: set[str], overwrite: bool = False
) -> bool:
    """Deploy configs for roles if not already deployed.

    Returns True if all deployments succeeded, False otherwise.
    """
    for role in roles:
        if overwrite or not app_ctx.config_deployer.is_deployed(role):
            result = app_ctx.config_deployer.deploy_role(role, overwrite=overwrite)
            if result.success:
                # Only print a message for newly deployed or overwritten configs
                if overwrite or "already exists" not in result.message:
                    console.print(f"[dim]Deployed config for {role}[/]")
            else:
                console.print(f"[red]Error:[/] Failed to deploy config for {role}")
                console.print(f"  {result.message}")
                return False
    return True


def list_tags(ctx: typer.Context) -> None:
    """List all available tags that can be used with 'menv make'.

    Example:
        menv list
        menv ls
    """
    app_ctx: AppContext = ctx.obj
    tags_map = app_ctx.playbook.get_tags_map()

    table = Table(title="Available Tags")
    table.add_column("Role", style="cyan")
    table.add_column("Tags", style="green")

    for role, tags in sorted(tags_map.items()):
        table.add_row(role, ", ".join(tags))

    console.print(table)
    console.print()
    console.print("[bold]Tag Groups:[/] (expanded automatically)")
    for group, tags in TAG_GROUPS.items():
        console.print(f"  [cyan]{group}[/] → {', '.join(tags)}")
    console.print()
    # Sort profiles: common first, then others alphabetically
    profiles_to_show = []
    if "common" in VALID_PROFILES:
        profiles_to_show.append("common")
    profiles_to_show.extend(sorted(VALID_PROFILES - {"common"}))

    profile_list = []
    for p in profiles_to_show:
        aliases = sorted(a for a, target in PROFILE_ALIASES.items() if target == p)
        alias_str = f" ({', '.join(aliases)})" if aliases else ""
        suffix = " (default)" if p == "common" else ""
        profile_list.append(f"{p}{alias_str}{suffix}")

    console.print(f"[bold]Profiles:[/] {', '.join(profile_list)}")


def make(
    ctx: typer.Context,
    tag: str = typer.Argument(
        ...,
        help="Ansible tag to run (e.g., rust, python-tools, shell, brew-cask).",
    ),
    profile: str = typer.Argument(
        "common",
        help="Profile to use (common, macbook/mbk, mac-mini/mmn).",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Enable verbose output.",
    ),
    overwrite: bool = typer.Option(
        False,
        "--overwrite",
        "-o",
        help="Overwrite existing configuration files.",
    ),
) -> None:
    """Run Ansible tasks with the specified tag and profile.

    Examples:
        menv make rust              # Run rust tasks with common profile
        menv make python-tools      # Run python-tools with common profile
        menv make brew-cask mmn     # Run brew-cask with mac-mini profile
        menv make shell macbook     # Run shell with macbook profile
        menv list                   # List available tags
    """
    # Resolve profile aliases
    resolved_profile = PROFILE_ALIASES.get(profile, profile)

    # Validate profile
    if resolved_profile not in VALID_PROFILES:
        profile_aliases = sorted(
            alias for alias, p in PROFILE_ALIASES.items() if p in VALID_PROFILES
        )
        console.print(
            f"[bold red]Error:[/] Invalid profile '{profile}'. "
            f"Valid profiles: {', '.join(sorted(VALID_PROFILES))} (aliases: {', '.join(profile_aliases)})"
        )
        raise typer.Exit(code=1)

    # Resolve tag groups
    tags_to_run = TAG_GROUPS.get(tag, [tag])

    # Get app context
    app_ctx: AppContext = ctx.obj

    # Validate tags exist in playbook
    all_tags = set(app_ctx.playbook.get_all_tags())
    # Tag groups like "rust" are valid CLI shortcuts, individual tags must exist
    for t in tags_to_run:
        if t not in all_tags:
            console.print(
                f"[bold red]Error:[/] Unknown tag '{t}'. "
                "Use 'menv ls' to see available tags."
            )
            raise typer.Exit(code=1)

    # Auto-deploy configs for roles that will be executed
    roles_to_deploy = _get_roles_for_tags(app_ctx, tags_to_run)
    if not _deploy_configs_for_roles(app_ctx, roles_to_deploy, overwrite=overwrite):
        raise typer.Exit(code=1)

    console.print(f"[bold green]Running:[/] {tag}")
    if resolved_profile != "common":
        console.print(f"[bold green]Profile:[/] {resolved_profile}")
    console.print()

    try:
        app_ctx.ansible_runner.run_playbook(
            profile=resolved_profile,
            tags=tags_to_run,
            verbose=verbose,
        )
        console.print()
        console.print("[bold green]✓ Completed successfully![/]")
    except AnsibleExecutionError as e:
        exit_code = e.returncode if e.returncode is not None else 1
        console.print()
        console.print(f"[bold red]✗ Failed with exit code {exit_code}[/]")
        raise typer.Exit(code=exit_code)
