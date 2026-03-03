"""SSH command stubs — execution is handled by menv-internal binary.

These stubs exist to provide CLI structure and help text for Typer.
Actual behavior is dispatched to the Rust binary via app.py callback.
If the binary is unavailable, these stubs report the missing binary.
"""

from __future__ import annotations

import typer

ssh_app = typer.Typer(
    name="ssh",
    help="Internal SSH key management.",
    no_args_is_help=True,
)

err_console_msg = (
    "Error: menv-internal binary not found. Run 'just build-internal' to build it."
)


@ssh_app.command("gk")
def generate_key(
    key_type: str = typer.Argument(..., help="SSH key type.", metavar="TYPE"),
    host: str = typer.Argument(..., help="Host alias."),
) -> None:
    """Generate a key and config snippet for a host."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)


@ssh_app.command("ls")
def list_hosts() -> None:
    """List configured SSH hosts."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)


@ssh_app.command("rm")
def remove_host(
    host: str = typer.Argument(..., help="Host alias."),
) -> None:
    """Remove SSH key and config for a host."""
    typer.echo(err_console_msg, err=True)
    raise typer.Exit(1)
