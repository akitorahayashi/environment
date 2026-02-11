"""Ansible playbook execution wrapper."""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

from rich.console import Console

from menv.exceptions import AnsibleExecutionError
from menv.protocols.ansible_paths import AnsiblePathsProtocol
from menv.protocols.ansible_runner import AnsibleRunnerProtocol
from menv.services.ansible_paths import AnsiblePaths


class AnsibleRunner(AnsibleRunnerProtocol):
    """Run bundled Ansible playbooks."""

    def __init__(
        self,
        paths: AnsiblePathsProtocol | None = None,
        console: Console | None = None,
    ) -> None:
        self._paths = paths or AnsiblePaths()
        self._console = console or Console()

    def run_playbook(
        self,
        profile: str,
        tags: list[str] | None = None,
        verbose: bool = False,
    ) -> None:
        """Execute ansible-playbook with the specified profile."""
        ansible_dir = self._paths.ansible_dir()
        playbook_path = ansible_dir / "playbook.yml"
        config_path = ansible_dir / "ansible.cfg"
        local_config_root = Path.home() / ".config" / "menv" / "roles"

        cmd: list[str | Path] = [
            "uv",
            "run",
            "ansible-playbook",
            str(playbook_path),
            "-e",
            f"profile={profile}",
            "-e",
            f"config_dir_abs_path={ansible_dir}",
            "-e",
            f"repo_root_path={ansible_dir.parent}",
            "-e",
            f"local_config_root={local_config_root}",
        ]

        if tags:
            cmd.extend(["--tags", ",".join(tags)])

        if verbose:
            cmd.append("-vvv")

        env = os.environ.copy()
        env["ANSIBLE_CONFIG"] = str(config_path)

        self._console.print(
            f"[bold blue]Running ansible-playbook for profile:[/] {profile}"
        )
        if tags:
            self._console.print(f"[dim]Tags: {', '.join(tags)}[/]")
        self._console.print()

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

            if process.returncode != 0:
                raise AnsibleExecutionError(
                    f"ansible-playbook failed with exit code {process.returncode}",
                    returncode=process.returncode,
                )

        except FileNotFoundError as e:
            self._console.print(
                "[bold red]Error:[/] ansible-playbook not found. "
                "Please ensure Ansible is installed."
            )
            raise AnsibleExecutionError(
                "ansible-playbook not found", returncode=1
            ) from e
        except KeyboardInterrupt:
            self._console.print("\n[yellow]Interrupted by user[/]")
            raise AnsibleExecutionError("Interrupted by user", returncode=130)
