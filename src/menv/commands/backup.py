"""Backup command for backing up system settings and configurations."""

import subprocess
import sys

import typer
from rich.console import Console

from menv.core.paths import get_ansible_dir

console = Console()

# Available backup targets
BACKUP_TARGETS = {
    "system": {
        "script": "scripts/system/backup-system.py",
        "description": "Backup macOS system defaults",
    },
    "vscode": {
        "script": "scripts/editor/backup-extensions.py",
        "description": "Backup VSCode extensions list",
    },
    "vscode-extensions": {
        "script": "scripts/editor/backup-extensions.py",
        "description": "Backup VSCode extensions list (alias)",
    },
}


def list_targets() -> None:
    """List available backup targets.

    Example:
        menv backup list
        menv bk ls
    """
    console.print("[bold]Available backup targets:[/]")
    console.print()
    for target, info in BACKUP_TARGETS.items():
        if target == "vscode-extensions":
            continue  # Skip alias in list
        console.print(f"  [cyan]{target}[/] - {info['description']}")
    console.print()
    console.print("[dim]Usage: menv backup <target>[/]")


def backup(
    target: str = typer.Argument(
        ...,
        help="Backup target (system, vscode).",
    ),
) -> None:
    """Backup system settings or configurations.

    Examples:
        menv backup system          # Backup macOS defaults
        menv backup vscode          # Backup VSCode extensions
        menv bk system              # Alias
        menv backup list            # List available targets
    """
    # Handle list command
    if target in ("list", "ls"):
        list_targets()
        return

    # Validate target
    if target not in BACKUP_TARGETS:
        console.print(
            f"[bold red]Error:[/] Unknown backup target '{target}'. "
            f"Valid targets: {', '.join(t for t in BACKUP_TARGETS if t != 'vscode-extensions')}"
        )
        raise typer.Exit(code=1)

    target_info = BACKUP_TARGETS[target]
    ansible_dir = get_ansible_dir()
    script_path = ansible_dir / target_info["script"]

    if not script_path.exists():
        console.print(f"[bold red]Error:[/] Backup script not found: {script_path}")
        raise typer.Exit(code=1)

    console.print(f"[bold blue]🔄 Running backup:[/] {target_info['description']}")
    console.print()

    try:
        process = subprocess.Popen(
            [sys.executable, str(script_path)],
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        if process.stdout:
            for line in process.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()

        process.wait()

        if process.returncode == 0:
            console.print()
            console.print("[bold green]✓ Backup completed successfully![/]")
        else:
            console.print()
            console.print(
                f"[bold red]✗ Backup failed with exit code {process.returncode}[/]"
            )
            raise typer.Exit(code=process.returncode)

    except FileNotFoundError:
        console.print("[bold red]Error:[/] Python interpreter not found")
        raise typer.Exit(code=1)
