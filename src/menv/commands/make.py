"""Make command for running individual Ansible tasks."""

from __future__ import annotations

from typing import TYPE_CHECKING

import typer
from rich.console import Console
from rich.table import Table

if TYPE_CHECKING:
    from menv.context import AppContext

console = Console()

# Predefined tag groups that combine multiple tags
TAG_GROUPS = {
    "rust": ["rust-platform", "rust-tools"],
    "python": ["python-platform", "python-tools"],
    "nodejs": ["nodejs-platform", "nodejs-tools"],
    "go": ["go-platform", "go-tools"],
}

# Valid profiles and their aliases
VALID_PROFILES = {"common", "macbook", "mac-mini"}
PROFILE_ALIASES = {
    "mmn": "mac-mini",
    "mbk": "macbook",
    "cmn": "common",
}

# Available tags from playbook.yml - grouped by role
AVAILABLE_TAGS = {
    "brew": ["brew-formulae", "brew-cask"],
    "python": ["python-platform", "python-tools", "aider", "uv"],
    "nodejs": ["nodejs-platform", "nodejs-tools", "llm"],
    "ruby": ["ruby"],
    "rust": ["rust-platform", "rust-tools"],
    "go": ["go-platform", "go-tools"],
    "vcs": ["git", "jj"],
    "gh": ["gh"],
    "shell": ["shell"],
    "ssh": ["ssh"],
    "editor": ["editor", "vscode", "cursor", "xcode"],
    "coderabbit": ["coderabbit"],
    "system": ["system"],
    "docker": ["docker"],
}

# Mapping from tags to their parent role names
TAG_TO_ROLE = {}
for role, tags in AVAILABLE_TAGS.items():
    for tag in tags:
        TAG_TO_ROLE[tag] = role
    # Also map role name itself (for tag groups like "rust" -> "rust")
    TAG_TO_ROLE[role] = role


def _get_roles_for_tags(app_ctx: "AppContext", tags: list[str]) -> set[str]:
    """Get unique role names for a list of tags that have config directories."""
    roles_with_config = app_ctx.config_deployer.roles_with_config

    roles = set()
    for tag in tags:
        if tag in TAG_TO_ROLE:
            role = TAG_TO_ROLE[tag]
            # Only include roles that have config directories
            if role in roles_with_config:
                roles.add(role)
    return roles


def _deploy_configs_for_roles(app_ctx: "AppContext", roles: set[str]) -> bool:
    """Deploy configs for roles if not already deployed.

    Returns True if all deployments succeeded, False otherwise.
    """
    for role in roles:
        if not app_ctx.config_deployer.is_deployed(role):
            result = app_ctx.config_deployer.deploy_role(role, overlay=False)
            if result.success:
                console.print(f"[dim]Deployed config for {role}[/]")
            else:
                console.print(f"[red]Error:[/] Failed to deploy config for {role}")
                console.print(f"  {result.message}")
                return False
    return True


def list_tags() -> None:
    """List all available tags that can be used with 'menv make'.

    Example:
        menv make list
        menv mk ls
    """
    table = Table(title="Available Tags")
    table.add_column("Role", style="cyan")
    table.add_column("Tags", style="green")

    for role, tags in AVAILABLE_TAGS.items():
        table.add_row(role, ", ".join(tags))

    console.print(table)
    console.print()
    console.print("[bold]Tag Groups:[/] (expanded automatically)")
    for group, tags in TAG_GROUPS.items():
        console.print(f"  [cyan]{group}[/] → {', '.join(tags)}")
    console.print()
    console.print("[bold]Profiles:[/] common (default), macbook/mbk, mac-mini/mmn")


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
) -> None:
    """Run Ansible tasks with the specified tag and profile.

    Examples:
        menv make rust              # Run rust tasks with common profile
        menv make python-tools      # Run python-tools with common profile
        menv make brew-cask mmn     # Run brew-cask with mac-mini profile
        menv make shell macbook     # Run shell with macbook profile
        menv mk list                # List available tags
    """
    # Resolve profile aliases
    resolved_profile = PROFILE_ALIASES.get(profile, profile)

    # Validate profile
    if resolved_profile not in VALID_PROFILES:
        console.print(
            f"[bold red]Error:[/] Invalid profile '{profile}'. "
            f"Valid profiles: {', '.join(sorted(VALID_PROFILES))}"
        )
        raise typer.Exit(code=1)

    # Resolve tag groups
    tags_to_run = TAG_GROUPS.get(tag, [tag])

    # Get app context
    app_ctx: AppContext = ctx.obj

    # Auto-deploy configs for roles that will be executed
    roles_to_deploy = _get_roles_for_tags(app_ctx, tags_to_run)
    if not _deploy_configs_for_roles(app_ctx, roles_to_deploy):
        raise typer.Exit(code=1)

    console.print(f"[bold green]Running:[/] {tag}")
    if resolved_profile != "common":
        console.print(f"[bold green]Profile:[/] {resolved_profile}")
    console.print()

    exit_code = app_ctx.ansible_runner.run_playbook(
        profile=resolved_profile,
        tags=tags_to_run,
        verbose=verbose,
    )

    if exit_code == 0:
        console.print()
        console.print("[bold green]✓ Completed successfully![/]")
    else:
        console.print()
        console.print(f"[bold red]✗ Failed with exit code {exit_code}[/]")
        raise typer.Exit(code=exit_code)
