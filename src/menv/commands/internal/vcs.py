"""VCS command stubs — execution is handled by menv-internal binary.

These stubs exist to provide CLI structure and help text for Typer.
Actual behavior is dispatched to the Rust binary via app.py callback.
If the binary is unavailable, these stubs report the missing binary.
"""

from __future__ import annotations

import typer

vcs_app = typer.Typer(
    name="vcs",
    help="Internal VCS helpers.",
    no_args_is_help=True,
)

err_console_msg = (
    "Error: menv-internal binary not found. Run 'just build-internal' to build it."
)


@vcs_app.command("delete-submodule")
def delete_submodule(
    submodule_path: str = typer.Argument(..., help="Relative path to the submodule."),
) -> None:
    """Delete a git submodule completely."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)
