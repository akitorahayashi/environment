"""Make command for running individual Ansible tasks."""

import typer
from rich.console import Console
from rich.table import Table

from menv.core.runner import run_ansible_playbook

console = Console()

# Predefined tag groups that combine multiple tags
TAG_GROUPS = {
    "rust": ["rust-platform", "rust-tools"],
    "python": ["python-platform", "python-tools"],
    "nodejs": ["nodejs-platform", "nodejs-tools"],
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
    "vcs": ["git", "jj"],
    "gh": ["gh"],
    "shell": ["shell"],
    "ssh": ["ssh"],
    "editor": ["editor", "vscode", "cursor", "xcode"],
    "coderabbit": ["coderabbit"],
    "system": ["system"],
    "docker": ["docker"],
}


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

    console.print(f"[bold green]Running:[/] {tag}")
    if resolved_profile != "common":
        console.print(f"[bold green]Profile:[/] {resolved_profile}")
    console.print()

    exit_code = run_ansible_playbook(
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
