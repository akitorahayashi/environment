"""Mock AnsiblePathsProtocol implementation."""

from __future__ import annotations

from pathlib import Path

from menv.protocols import AnsiblePathsProtocol


class MockAnsiblePaths(AnsiblePathsProtocol):
    """In-memory path provider for tests."""

    def __init__(self, ansible_dir: Path | None = None) -> None:
        self._ansible_dir = ansible_dir or Path("/mock/ansible")

    def ansible_dir(self) -> Path:
        return self._ansible_dir

    def playbook_path(self) -> Path:
        return self._ansible_dir / "playbook.yml"

    def ansible_config_path(self) -> Path:
        return self._ansible_dir / "ansible.cfg"
