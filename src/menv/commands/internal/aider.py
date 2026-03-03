"""Aider command stubs — execution is handled by menv-internal binary.

These stubs exist to provide CLI structure and help text for Typer.
Actual behavior is dispatched to the Rust binary via app.py callback.
If the binary is unavailable, these stubs report the missing binary.
"""

from __future__ import annotations

from typing import Optional

import typer

aider_app = typer.Typer(
    name="aider",
    help="Internal aider helpers.",
    no_args_is_help=True,
)

err_console_msg = (
    "Error: menv-internal binary not found. Run 'just build-internal' to build it."
)


@aider_app.command("run")
def run(
    directories: Optional[list[str]] = typer.Option(
        None, "-d", "--dir", help="Add a directory to the aider context."
    ),
    extensions: Optional[list[str]] = typer.Option(
        None, "-e", "--ext", help="Add files by extension (recursively)."
    ),
    files: Optional[list[str]] = typer.Option(
        None, "-f", "--files", help="Add specific files to the aider context."
    ),
    yolo: bool = typer.Option(
        False, "-y", "--yes", help="Automatically accept aider suggestions."
    ),
    message: Optional[str] = typer.Option(
        None, "-m", "--message", help="Send a one-off message to aider."
    ),
    targets: Optional[list[str]] = typer.Argument(None, help="Additional files."),
) -> None:
    """Invoke aider with curated defaults."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)


@aider_app.command("set-model")
def set_model(
    model: Optional[str] = typer.Argument(None, help="Ollama model name."),
) -> None:
    """Set the default Ollama model for aider (eval-friendly output)."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)


@aider_app.command("unset-model")
def unset_model() -> None:
    """Unset the configured Ollama model (eval-friendly output)."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)


@aider_app.command("list-models")
def list_models() -> None:
    """List available Ollama models."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)
