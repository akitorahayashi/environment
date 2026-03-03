"""Assembly-only router for hidden internal commands.

Creates ``internal_app`` and registers domain sub-apps.
When the bundled ``menv-internal`` binary is available, commands are
dispatched to the Rust binary. Otherwise, Python implementations are used.
"""

import sys

import typer

from menv.commands.internal.aider import aider_app
from menv.commands.internal.dispatch import dispatch
from menv.commands.internal.shell import shell_app
from menv.commands.internal.ssh import ssh_app
from menv.commands.internal.vcs import vcs_app
from menv.internal_binary.locator import is_available

internal_app = typer.Typer(
    name="internal",
    help="Internal commands used by shell aliases.",
    hidden=True,
    no_args_is_help=True,
    invoke_without_command=True,
)


@internal_app.callback()
def _internal_callback(ctx: typer.Context) -> None:
    """Intercept internal commands and dispatch to bundled binary when available."""
    if ctx.invoked_subcommand is None:
        return

    if not is_available():
        # Fall through to Python implementations
        return

    # Forward everything after "internal" to the Rust binary
    try:
        internal_idx = sys.argv.index("internal")
    except ValueError:
        return

    args = sys.argv[internal_idx + 1 :]
    try:
        code = dispatch(args)
    except (FileNotFoundError, PermissionError):
        return
    raise typer.Exit(code)


internal_app.add_typer(vcs_app, name="vcs")
internal_app.add_typer(ssh_app, name="ssh")
internal_app.add_typer(aider_app, name="aider")
internal_app.add_typer(shell_app, name="shell")
