"""Create command for full profile setup (macbook, mac-mini)."""

import typer
from rich.console import Console

from menv.runner import run_ansible_playbook

console = Console()

# Valid profiles and their aliases
VALID_PROFILES = {"macbook", "mac-mini"}
PROFILE_ALIASES = {
    "mmn": "mac-mini",
    "mbk": "macbook",
}

# Tags to run for full profile setup (order matters)
FULL_SETUP_TAGS = [
    "shell",
    "ssh",
    "system",
    "git",
    "jj",
    "gh",
    "python-platform",
    "python-tools",
    "uv",
    "nodejs-platform",
    "nodejs-tools",
    "vscode",
    "cursor",
    "coderabbit",
    "ruby",
    "rust-platform",
    "rust-tools",
    "brew-formulae",
]


def create(
    profile: str = typer.Argument(
        ...,
        help="Profile to setup (macbook/mbk, mac-mini/mmn).",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Enable verbose output.",
    ),
) -> None:
    """Run full environment setup for a profile.

    This runs all common setup tasks for the specified profile,
    equivalent to the old 'make macbook' or 'make mac-mini'.

    Examples:
        menv create macbook     # Full setup for MacBook
        menv create mac-mini    # Full setup for Mac mini
        menv cr mbk             # Alias for macbook
        menv cr mmn             # Alias for mac-mini
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

    console.print(f"[bold blue]🚀 Starting full setup for {resolved_profile}...[/]")
    console.print()

    # Run all tags in order
    for tag in FULL_SETUP_TAGS:
        console.print(f"[bold green]>>> {tag}[/]")
        exit_code = run_ansible_playbook(
            profile=resolved_profile,
            tags=[tag],
            verbose=verbose,
        )
        if exit_code != 0:
            console.print()
            console.print(
                f"[bold red]✗ Failed at '{tag}' with exit code {exit_code}[/]"
            )
            raise typer.Exit(code=exit_code)

    console.print()
    console.print(
        f"[bold green]✅ {resolved_profile} full setup completed successfully![/]"
    )
