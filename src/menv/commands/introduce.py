"""Introduce command - interactive setup guide."""

from __future__ import annotations

import typer
from rich.console import Console
from rich.panel import Panel
from rich.text import Text

from menv.models.introduction_phases import (
    IntroductionPhase,
    get_optional_commands,
    get_phases,
)

console = Console()

VALID_PROFILES = {"macbook", "mac-mini"}
PROFILE_ALIASES = {"mmn": "mac-mini", "mbk": "macbook"}


def introduce(
    profile: str = typer.Argument(..., help="Profile (macbook/mbk, mac-mini/mmn)"),
    no_wait: bool = typer.Option(
        False,
        "--no-wait",
        "-n",
        "-nw",
        help="Don't wait for user input between phases.",
    ),
) -> None:
    """Interactive setup guide for a profile.

    Displays commands to run in each phase. You can run commands
    in parallel by opening multiple terminal windows.

    Examples:
        menv introduce macbook
        menv itr mbk
        menv itr mmn --no-wait
        menv itr mbk -nw
    """
    resolved = PROFILE_ALIASES.get(profile, profile)
    if resolved not in VALID_PROFILES:
        console.print(f"[bold red]Error:[/] Invalid profile '{profile}'.")
        console.print(
            f"Valid profiles: {', '.join(sorted(VALID_PROFILES))} (aliases: mbk, mmn)"
        )
        raise typer.Exit(1)

    # Header
    console.print()
    console.print(
        Panel(
            Text.from_markup(
                f"[bold]menv: macOS Environment Setup Guide[/]\n"
                f"Profile: [cyan]{resolved}[/]"
            ),
            border_style="blue",
        )
    )
    console.print()

    # Phase 0: Brew
    _show_brew_phase(resolved, no_wait)

    # Phase 1-4: Tasks
    phases = get_phases(resolved)
    for i, phase in enumerate(phases, 1):
        _show_phase(i, phase, no_wait)

    # Footer
    _show_completion(resolved)


def _show_brew_phase(profile: str, no_wait: bool) -> None:
    """Show Phase 0: Brew installation."""
    # Use short aliases for profile
    profile_alias = "mbk" if profile == "macbook" else "mmn"

    console.print("[bold]Phase 0: Brew Dependencies[/]")
    console.print("═" * 50)
    console.print()
    console.print("Install all required brew formulae first (prevents lock conflicts):")
    console.print()
    console.print(f"  [green]menv make brew-deps {profile_alias}[/]")
    console.print()
    if not no_wait:
        console.input("[dim]Press [Enter] when done...[/]")
    console.print()


def _show_phase(num: int, phase: IntroductionPhase, no_wait: bool) -> None:
    """Show a single phase."""
    dep_note = ""
    if phase.dependencies:
        dep_note = f" [dim](requires: {', '.join(phase.dependencies)})[/]"

    console.print(f"[bold]Phase {num}: {phase.name}[/]{dep_note}")
    console.print("═" * 50)
    console.print()
    console.print(phase.description)
    console.print()
    for cmd in phase.commands:
        console.print(f"  [green]{cmd}[/]")
    console.print()
    if not no_wait:
        console.input("[dim]Press [Enter] when done...[/]")
    console.print()


def _show_completion(profile: str) -> None:
    """Show completion message."""
    optional_cmds = get_optional_commands(profile)
    optional_text = "\n".join(f"  {cmd}" for cmd in optional_cmds)

    console.print(
        Panel(
            Text.from_markup(
                "[bold green]Setup complete![/]\n\n"
                "[dim]Optional steps:[/]\n" + optional_text
            ),
            border_style="green",
        )
    )
