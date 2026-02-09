"""Create command for full environment setup."""

from __future__ import annotations

from typing import TYPE_CHECKING, TypedDict

import typer
from rich.console import Console
from rich.panel import Panel

from menv.constants import FULL_SETUP_TAGS, MACHINE_PROFILES, PROFILE_ALIASES

if TYPE_CHECKING:
    from menv.context import AppContext

console = Console()


# Data structure for optional tasks
class OptionalTask(TypedDict):
    tag: str
    name: str
    description: str
    profile_specific: bool  # Whether the task requires a profile argument


# Optional tasks that are skipped for stability/speed reasons
OPTIONAL_TASKS: list[OptionalTask] = [
    {
        "tag": "brew-cask",
        "name": "GUI Applications",
        "description": "Install GUI apps via Homebrew Cask",
        "profile_specific": True,
    },
    {
        "tag": "ollama-models",
        "name": "Ollama Models",
        "description": "Download Ollama models (requires 'ollama serve' running)",
        "profile_specific": False,
    },
    {
        "tag": "mlx-models",
        "name": "MLX Models",
        "description": "Download MLX models via huggingface-cli",
        "profile_specific": False,
    },
]


def _print_optional_tasks_summary(profile: str) -> None:
    """Show summary of optional tasks that were skipped."""
    if not OPTIONAL_TASKS:
        return

    lines = []
    lines.append(
        "The following optional components were skipped to ensure stability/speed:\n"
    )

    for task in OPTIONAL_TASKS:
        cmd_args = f"{task['tag']}"

        lines.append(f"[bold cyan]➤ {task['name']}[/]")
        lines.append(f"  Description: {task['description']}")
        lines.append(f"  Command:     [green]menv make {cmd_args}[/]")
        lines.append("")  # Empty line for spacing

    console.print()
    console.print(
        Panel(
            "\n".join(lines).rstrip(),
            title="Optional Steps",
            border_style="yellow",
            expand=False,
        )
    )


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
    overwrite: bool = typer.Option(
        False,
        "--overwrite",
        "-o",
        help="Overwrite existing configuration files.",
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
    if resolved_profile not in MACHINE_PROFILES:
        machine_aliases = sorted(
            alias for alias, p in PROFILE_ALIASES.items() if p in MACHINE_PROFILES
        )
        console.print(
            f"[bold red]Error:[/] Invalid profile '{profile}'. "
            f"Valid profiles: {', '.join(sorted(MACHINE_PROFILES))} (aliases: {', '.join(machine_aliases)})"
        )
        raise typer.Exit(code=1)

    # Get app context
    app_ctx: AppContext = ctx.obj

    # Validate all tags exist - single pass for efficiency
    all_known_tags = set(app_ctx.playbook.get_all_tags())
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
        if (role := app_ctx.playbook.get_role_for_tag(tag))
        and role in roles_with_config
    }

    # Deploy configs for all roles upfront using deploy_multiple_roles
    if roles_to_deploy:
        console.print("[bold]Deploying configurations...[/]")
        results = app_ctx.config_deployer.deploy_multiple_roles(
            sorted(list(roles_to_deploy)), overwrite=overwrite
        )

        for result in results:
            if result.success:
                # Only print a message for newly deployed configs
                if overwrite or "already exists" not in result.message:
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

    # Print optional tasks summary
    _print_optional_tasks_summary(resolved_profile)
