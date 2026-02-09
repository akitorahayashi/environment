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
    ) -> None:
        """Execute ansible-playbook.

        Raises:
            AnsibleExecutionError: If execution fails.
        """
        ...
