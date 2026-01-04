"""Create command for full environment setup."""

from __future__ import annotations

from typing import TYPE_CHECKING

import typer
from rich.console import Console
from rich.panel import Panel

if TYPE_CHECKING:
    from menv.context import AppContext

console = Console()

# Valid profiles and their aliases
VALID_PROFILES = {"macbook", "mac-mini"}
PROFILE_ALIASES = {
    "mmn": "mac-mini",
    "mbk": "macbook",
}

# Ordered list of tags for full setup
# This defines the execution order for a complete environment setup
FULL_SETUP_TAGS = [
    # Phase 0: Brew dependencies (must be first)
    "brew-formulae",
    # Phase 1: Configuration
    "shell",
    "system",
    "git",
    "jj",
    "gh",
    # Phase 2: Language runtimes
    "python-platform",
    "nodejs-platform",
    "ruby",
    "rust-platform",
    "go-platform",
    # Phase 3: Language tools (require runtimes)
    "python-tools",
    "uv",
    "nodejs-tools",
    "rust-tools",
    "go-tools",
    # Phase 4: Editors
    "vscode",
    "cursor",
    # Phase 5: Additional tools
    "aider",
    "llm",
    "xcode",
    "editor",
]


def create(
    ctx: typer.Context,
    profile: str = typer.Argument(
        ...,
        help="Profile to create (macbook/mbk, mac-mini/mmn).",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Enable verbose output.",
    ),
) -> None:
    """Create a complete development environment for a profile.

    This command runs all setup tasks in the correct order to provision
    a complete macOS development environment.

    Examples:
        menv create macbook
        menv create mac-mini
        menv cr mbk
        menv cr mmn -v
    """
    # Resolve profile aliases
    resolved_profile = PROFILE_ALIASES.get(profile, profile)

    # Validate profile
    if resolved_profile not in VALID_PROFILES:
        console.print(
            f"[bold red]Error:[/] Invalid profile '{profile}'. "
            f"Valid profiles: {', '.join(sorted(VALID_PROFILES))} (aliases: mbk, mmn)"
        )
        raise typer.Exit(code=1)

    # Get app context
    app_ctx: AppContext = ctx.obj

    # Validate all tags exist - single pass for efficiency
    all_known_tags = set(app_ctx.playbook_service.get_all_tags())
    invalid_tags = [tag for tag in FULL_SETUP_TAGS if tag not in all_known_tags]
    if invalid_tags:
        console.print(
            f"[bold red]Error:[/] Invalid tags in setup: {', '.join(invalid_tags)}"
        )
        raise typer.Exit(code=1)

    # Header
    console.print()
    console.print(
        Panel(
            f"[bold]menv: Creating {resolved_profile} environment[/]\n"
            f"This will run {len(FULL_SETUP_TAGS)} tasks.",
            border_style="blue",
        )
    )
    console.print()

    # Collect all unique roles that need config deployment
    roles_with_config = set(app_ctx.config_deployer.roles_with_config)
    roles_to_deploy = {
        role
        for tag in FULL_SETUP_TAGS
        if (role := app_ctx.playbook_service.get_role_for_tag(tag))
        and role in roles_with_config
    }

    # Deploy configs for all roles upfront using deploy_multiple_roles
    if roles_to_deploy:
        console.print("[bold]Deploying configurations...[/]")
        results = app_ctx.config_deployer.deploy_multiple_roles(
            sorted(list(roles_to_deploy)), overlay=False
        )

        for result in results:
            if result.success:
                # Only print a message for newly deployed configs
                if "already exists" not in result.message:
                    console.print(f"  [dim]Deployed config for {result.role}[/]")
            else:
                # Failure - which will be the last item in results
                console.print(
                    f"  [red]Error:[/] Failed to deploy config for {result.role}"
                )
                console.print(f"    {result.message}")
                raise typer.Exit(code=1)
        console.print()

    # Run each tag
    for i, tag in enumerate(FULL_SETUP_TAGS, 1):
        console.print(f"[bold cyan][{i}/{len(FULL_SETUP_TAGS)}][/] Running: {tag}")

        exit_code = app_ctx.ansible_runner.run_playbook(
            profile=resolved_profile,
            tags=[tag],
            verbose=verbose,
        )

        if exit_code != 0:
            console.print(f"  [red]✗ Failed with exit code {exit_code}[/]")
            console.print()
            console.print(
                Panel(
                    f"[bold red]Setup failed at step {i}/{len(FULL_SETUP_TAGS)}:[/]\n"
                    f"  Tag: {tag}\n"
                    f"  Exit code: {exit_code}\n\n"
                    "[dim]Fix the issue and run the command again to continue.[/]",
                    border_style="red",
                )
            )
            raise typer.Exit(code=exit_code)
        else:
            console.print("  [green]✓ Completed[/]")

    # Success
    console.print()
    console.print(
        Panel(
            f"[bold green]✓ Environment created successfully![/]\n"
            f"Profile: {resolved_profile}",
            border_style="green",
        )
    )
