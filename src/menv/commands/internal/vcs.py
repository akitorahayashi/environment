"""Internal VCS commands."""

from __future__ import annotations

import subprocess
from pathlib import PurePosixPath

import typer
from rich.console import Console

vcs_app = typer.Typer(
    name="vcs",
    help="Internal VCS helpers.",
    no_args_is_help=True,
)

console = Console()
err_console = Console(stderr=True)


@vcs_app.command("delete-submodule")
def delete_submodule(
    submodule_path: str = typer.Argument(..., help="Relative path to the submodule."),
) -> None:
    """Delete a git submodule completely."""
    if ".." in PurePosixPath(submodule_path).parts or submodule_path.startswith("/"):
        err_console.print(
            f"Error: Invalid submodule path '{submodule_path}'. "
            "Must be a relative path without '..'."
        )
        raise typer.Exit(1)

    console.print(f"Deleting submodule {submodule_path}...")

    try:
        subprocess.run(["git", "submodule", "deinit", "-f", submodule_path], check=True)
        subprocess.run(["git", "rm", "-f", "-r", submodule_path], check=True)
        subprocess.run(["rm", "-rf", f".git/modules/{submodule_path}"], check=True)
    except subprocess.CalledProcessError as exc:
        err_console.print(f"Error: {exc}")
        raise typer.Exit(1)

    try:
        subprocess.run(
            ["git", "config", "--remove-section", f"submodule.{submodule_path}"],
            check=True,
            capture_output=True,
        )
    except subprocess.CalledProcessError as exc:
        if b"No such section" not in (exc.stderr or b""):
            err_console.print(
                f"Warning: Could not remove config section: "
                f"{(exc.stderr or b'').decode()}"
            )

    console.print(f"✅ Submodule {submodule_path} deleted successfully.")
