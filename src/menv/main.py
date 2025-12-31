"""Typer CLI application entry point for menv."""

from importlib import metadata
from typing import Optional

import typer
from rich.console import Console

from menv.commands.backup import backup
from menv.commands.code import code
from menv.commands.config import config
from menv.commands.introduce import introduce
from menv.commands.make import list_tags, make
from menv.commands.switch import switch
from menv.commands.update import update
from menv.context import AppContext
from menv.services.ansible_paths import AnsiblePaths
from menv.services.ansible_runner import AnsibleRunner
from menv.services.config_storage import ConfigStorage
from menv.services.version_checker import VersionChecker

console = Console()


def get_safe_version(package_name: str, fallback: str = "0.1.0") -> str:
    """Safely get the version of a package.

    Args:
        package_name: Name of the package.
        fallback: Default version if retrieval fails.

    Returns:
        Version string.
    """
    try:
        return metadata.version(package_name)
    except metadata.PackageNotFoundError:
        return fallback


def version_callback(value: Optional[bool]) -> None:
    """Print version and exit."""
    if value:
        version = get_safe_version("menv")
        console.print(f"menv version: {version}")
        raise typer.Exit()


app = typer.Typer(
    name="menv",
    help="macOS development environment provisioning CLI.",
    no_args_is_help=True,
)


@app.callback()
def main(
    ctx: typer.Context,
    version: Optional[bool] = typer.Option(
        None,
        "--version",
        "-V",
        callback=version_callback,
        is_eager=True,
        help="Show version and exit.",
    ),
) -> None:
    """menv - Provision and manage your macOS development environment."""
    ansible_paths = AnsiblePaths()
    ctx.obj = AppContext(
        config_storage=ConfigStorage(),
        ansible_paths=ansible_paths,
        ansible_runner=AnsibleRunner(paths=ansible_paths),
        version_checker=VersionChecker(),
    )


# Register introduce command (interactive setup guide) and alias
app.command(
    name="introduce",
    help=r"Interactive setup guide for a profile. \[aliases: itr]",
)(introduce)
app.command(name="itr", hidden=True)(introduce)

# Register make command (individual tasks) and alias
app.command(name="make", help=r"Run individual Ansible task by tag. \[aliases: mk]")(
    make
)
app.command(name="mk", hidden=True)(make)

# Register list command and alias
app.command(name="list", help=r"List available tags for make command. \[aliases: ls]")(
    list_tags
)
app.command(name="ls", hidden=True)(list_tags)

# Register update command and alias
app.command(name="update", help=r"Update menv to the latest version. \[aliases: u]")(
    update
)
app.command(name="u", hidden=True)(update)

# Register backup command and alias
app.command(
    name="backup", help=r"Backup system settings or configurations. \[aliases: bk]"
)(backup)
app.command(name="bk", hidden=True)(backup)

# Register config command and alias
app.command(name="config", help=r"Manage menv configuration. \[aliases: cf]")(config)
app.command(name="cf", hidden=True)(config)

# Register switch command and alias
app.command(
    name="switch", help=r"Switch VCS identity between personal and work. \[aliases: sw]"
)(switch)
app.command(name="sw", hidden=True)(switch)

# Register code command
app.command(name="code", help="Open menv source code in VS Code.")(code)


if __name__ == "__main__":
    app()
