"""Code command to open menv source code in VS Code."""

import shutil
import subprocess
from pathlib import Path

import typer
from rich.console import Console

console = Console()

MENV_REPO_URL = "git@github.com:akitorahayashi/menv.git"
MENV_REPO_PATH = Path.home() / "menv"


def _check_ssh_available() -> bool:
    """Check if SSH connection to GitHub is available."""
    try:
        result = subprocess.run(
            ["ssh", "-T", "git@github.com"],
            capture_output=True,
            text=True,
            timeout=10,
        )
        # GitHub returns exit code 1 with "successfully authenticated" message
        return "successfully authenticated" in result.stderr
    except (subprocess.TimeoutExpired, subprocess.SubprocessError):
        return False


def _clone_menv_repo() -> bool:
    """Clone menv repository to home directory."""
    try:
        subprocess.run(
            ["git", "clone", MENV_REPO_URL, str(MENV_REPO_PATH)],
            check=True,
            timeout=60,
        )
        return True
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False


def code() -> None:
    """Open menv source code in VS Code.

    Clones the menv repository to ~/menv if it doesn't exist, then opens it
    in Visual Studio Code. This allows you to edit the menv codebase and
    create pull requests.

    Requirements:
        - SSH access to GitHub must be configured
        - The 'code' command must be installed (VS Code CLI)
        - ~/menv must not exist, or if it does, it must be a git repository

    Examples:
        menv code

    Raises:
        typer.Exit: If requirements are not met or VS Code fails to open.
    """
    # Check if 'code' command is available
    if not shutil.which("code"):
        console.print(
            "[yellow]Warning:[/] The 'code' command was not found in your PATH."
        )
        console.print(
            "[dim]Hint: In VS Code, open the Command Palette (Cmd+Shift+P) and run[/]"
        )
        console.print("[dim]'Shell Command: Install 'code' command in PATH'.[/]")
        raise typer.Exit(code=1)

    # Check if ~/menv already exists
    if MENV_REPO_PATH.exists():
        if (MENV_REPO_PATH / ".git").exists():
            # It's a git repo, just open it
            pass
        else:
            console.print(
                f"[bold red]Error:[/] '{MENV_REPO_PATH}' already exists but is not a git repository."
            )
            console.print("[dim]Please remove or rename it manually to proceed.[/]")
            raise typer.Exit(code=1)
    else:
        # Need to clone - check SSH first
        console.print("[dim]Checking SSH access to GitHub...[/]")
        if not _check_ssh_available():
            console.print("[bold red]Error:[/] SSH access to GitHub is not available.")
            console.print("[dim]Please configure SSH keys for GitHub first.[/]")
            console.print(
                "[dim]See: https://docs.github.com/en/authentication/connecting-to-github-with-ssh[/]"
            )
            raise typer.Exit(code=1)

        # Clone the repository
        console.print(f"[dim]Cloning menv repository to {MENV_REPO_PATH}...[/]")
        if not _clone_menv_repo():
            console.print("[bold red]Error:[/] Failed to clone menv repository.")
            raise typer.Exit(code=1)
        console.print("[green]Repository cloned successfully.[/]")

    # Open in VS Code
    try:
        subprocess.run(["code", str(MENV_REPO_PATH)], check=True)
        console.print(
            f"[dim]Opened menv project in VS Code[/] [dim cyan]({MENV_REPO_PATH})[/]"
        )
    except subprocess.CalledProcessError as e:
        console.print(f"[bold red]Error:[/] Failed to open VS Code: {e}")
        raise typer.Exit(code=1)
