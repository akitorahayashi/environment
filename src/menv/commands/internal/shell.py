"""Shell command stubs — execution is handled by menv-internal binary.

These stubs exist to provide CLI structure and help text for Typer.
Actual behavior is dispatched to the Rust binary via app.py callback.
If the binary is unavailable, these stubs report the missing binary.
"""

from __future__ import annotations

import typer

shell_app = typer.Typer(
    name="shell",
    help="Internal shell helper generators.",
    no_args_is_help=True,
)

err_console_msg = (
    "Error: menv-internal binary not found. Run 'just build-internal' to build it."
)


@shell_app.command("gen-gemini-aliases")
def gen_gemini_aliases() -> None:
    """Generate Gemini model aliases for shell initialization."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)


@shell_app.command("gen-vscode-workspace")
def gen_vscode_workspace(
    paths: list[str] = typer.Argument(..., help="Paths to include in the workspace."),
) -> None:
    """Generate a VSCode .code-workspace file from given paths."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)
