"""Assembly-only router for hidden internal commands.

Creates ``internal_app`` and registers domain sub-apps.
No command business logic lives here.
"""

import typer

from menv.commands.internal.aider import aider_app
from menv.commands.internal.shell import shell_app
from menv.commands.internal.ssh import ssh_app
from menv.commands.internal.vcs import vcs_app

internal_app = typer.Typer(
    name="internal",
    help="Internal commands used by shell aliases.",
    hidden=True,
    no_args_is_help=True,
)

internal_app.add_typer(vcs_app, name="vcs")
internal_app.add_typer(ssh_app, name="ssh")
internal_app.add_typer(aider_app, name="aider")
internal_app.add_typer(shell_app, name="shell")
