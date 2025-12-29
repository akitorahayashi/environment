"""Ansible playbook execution wrapper."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from rich.console import Console

from menv.core.paths import get_ansible_config_path, get_ansible_dir, get_playbook_path

console = Console()


def run_ansible_playbook(
    profile: str,
    tags: list[str] | None = None,
    verbose: bool = False,
) -> int:
    """Execute ansible-playbook with the specified profile.

    Args:
        profile: The profile name (e.g., 'macbook', 'mac-mini').
        tags: Optional list of tags to filter tasks.
        verbose: Enable verbose output.

    Returns:
        Exit code from ansible-playbook.
    """
    ansible_dir = get_ansible_dir()
    playbook_path = get_playbook_path()
    config_path = get_ansible_config_path()

    # Build command
    cmd: list[str | Path] = [
        "ansible-playbook",
        str(playbook_path),
        "-e",
        f"profile={profile}",
        "-e",
        f"config_dir_abs_path={ansible_dir}",
        "-e",
        f"repo_root_path={ansible_dir.parent}",
    ]

    if tags:
        cmd.extend(["--tags", ",".join(tags)])

    if verbose:
        cmd.append("-vvv")

    # Set up environment
    env = os.environ.copy()
    env["ANSIBLE_CONFIG"] = str(config_path)

    console.print(f"[bold blue]Running ansible-playbook for profile:[/] {profile}")
    if tags:
        console.print(f"[dim]Tags: {', '.join(tags)}[/]")
    console.print()

    try:
        process = subprocess.Popen(
            [str(c) for c in cmd],
            env=env,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )

        if process.stdout:
            for line in process.stdout:
                sys.stdout.write(line)
                sys.stdout.flush()

        process.wait()
        return process.returncode

    except FileNotFoundError:
        console.print(
            "[bold red]Error:[/] ansible-playbook not found. "
            "Please ensure Ansible is installed."
        )
        return 1
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/]")
        return 130
