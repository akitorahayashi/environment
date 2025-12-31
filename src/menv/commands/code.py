"""Code command to open menv source code in VS Code."""

import shutil
import subprocess
import tomllib
from pathlib import Path

import typer
from rich.console import Console

console = Console()


def find_menv_root() -> Path | None:
    """Find the menv project root directory.

    Searches for the project root by traversing up from the current module
    location until finding a directory containing pyproject.toml.

    Returns:
        Path to menv project root, or None if not found.
    """
    current = Path(__file__).resolve()

    # Traverse up to find pyproject.toml
    for parent in [current, *current.parents]:
        pyproject = parent / "pyproject.toml"
        if pyproject.exists():
            # Verify it's the menv project by parsing TOML
            try:
                with pyproject.open("rb") as f:
                    data = tomllib.load(f)
                if data.get("project", {}).get("name") == "menv":
                    return parent
            except tomllib.TOMLDecodeError:
                # Ignore malformed TOML files
                pass

    return None


def code() -> None:
    """Open menv source code in VS Code.

    Opens the menv project source directory in Visual Studio Code. This allows
    you to edit the menv codebase directly from the pipx installation without
    needing to clone the repository separately.

    If the 'code' command is not installed, displays a warning with installation
    instructions but does not fail.

    Examples:
        menv code

    Raises:
        typer.Exit: If menv root cannot be located or VS Code fails to open.
    """
    if not shutil.which("code"):
        console.print(
            "[yellow]Warning:[/] The 'code' command was not found in your PATH."
        )
        console.print(
            "[dim]Hint: In VS Code, open the Command Palette (Cmd+Shift+P) and run[/]"
        )
        console.print("[dim]'Shell Command: Install 'code' command in PATH'.[/]")
        return

    menv_root = find_menv_root()
    if not menv_root:
        console.print(
            "[bold red]Error:[/] Could not locate menv project root directory."
        )
        raise typer.Exit(code=1)

    try:
        subprocess.run(["code", str(menv_root)], check=True)
        console.print(
            f"[dim]✓ Opened menv project in VS Code[/] [dim cyan]({menv_root})[/]"
        )
    except subprocess.CalledProcessError as e:
        console.print(f"[bold red]Error:[/] Failed to open VS Code: {e}")
        raise typer.Exit(code=1)
