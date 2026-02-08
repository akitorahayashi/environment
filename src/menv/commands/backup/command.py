"""Backup command for backing up system settings and configurations."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Callable

import typer
from rich.console import Console

from menv.commands.backup.services import system as system_backup
from menv.commands.backup.services import vscode_extensions as vscode_backup

if TYPE_CHECKING:
    from pathlib import Path

    from menv.context import AppContext

console = Console()


@dataclass(frozen=True)
class BackupTarget:
    description: str
    role: str
    subpath: str
    run: Callable[..., int]


BACKUP_TARGETS: dict[str, BackupTarget] = {
    "system": BackupTarget(
        description="Backup macOS system defaults",
        role="system",
        subpath="common",
        run=lambda **kwargs: system_backup.run(**kwargs),
    ),
    "vscode": BackupTarget(
        description="Backup VSCode extensions list",
        role="editor",
        subpath="common",
        run=lambda **kwargs: vscode_backup.run(**kwargs),
    ),
}


def list_targets() -> None:
    """List available backup targets."""
    console.print("[bold]Available backup targets:[/]")
    console.print()
    for name, target in BACKUP_TARGETS.items():
        console.print(f"  [cyan]{name}[/] - {target.description}")
    console.print()
    console.print("[dim]Usage: menv backup <target>[/]")


def backup(
    ctx: typer.Context,
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
    if target in ("list", "ls"):
        list_targets()
        return

    if target == "vscode-extensions":
        target = "vscode"

    if target not in BACKUP_TARGETS:
        console.print(
            f"[bold red]Error:[/] Unknown backup target '{target}'. "
            f"Valid targets: {', '.join(BACKUP_TARGETS)}"
        )
        raise typer.Exit(code=1)

    app_ctx: AppContext = ctx.obj
    bt = BACKUP_TARGETS[target]

    local_config_dir: Path = (
        app_ctx.config_deployer.get_local_config_path(bt.role) / bt.subpath
    )

    console.print(f"[bold blue]🔄 Running backup:[/] {bt.description}")
    console.print()

    kwargs: dict[str, object] = {"config_dir": local_config_dir}

    if target == "system":
        definitions_path = local_config_dir / "definitions"
        if not definitions_path.exists():
            console.print(
                f"[dim]ℹ Local definitions not found at {definitions_path}. "
                "Using package defaults.[/]"
            )
            package_definitions_path = (
                app_ctx.config_deployer.get_package_config_path(bt.role)
                / bt.subpath
                / "definitions"
            )
            kwargs["definitions_dir"] = package_definitions_path

    exit_code = bt.run(**kwargs)

    if exit_code == 0:
        console.print()
        console.print("[bold green]✓ Backup completed successfully![/]")
    else:
        console.print()
        console.print(f"[bold red]✗ Backup failed with exit code {exit_code}[/]")
        raise typer.Exit(code=exit_code)
