"""Protocol for running Ansible playbooks."""

from __future__ import annotations

from typing import Protocol


class AnsibleRunnerProtocol(Protocol):
    """Ansible runner abstraction."""

    def run_playbook(
        self,
        profile: str,
        tags: list[str] | None = None,
        verbose: bool = False,
    ) -> int:
        """Execute ansible-playbook and return the exit code."""
        ...
