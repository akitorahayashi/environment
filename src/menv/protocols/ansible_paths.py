"""Protocol for resolving package Ansible resource paths."""

from __future__ import annotations

from pathlib import Path
from typing import Protocol


class AnsiblePathsProtocol(Protocol):
    """Ansible path resolution abstraction."""

    def ansible_dir(self) -> Path:
        """Get the path to the package ansible directory."""
        ...

    def playbook_path(self) -> Path:
        """Get the path to the main playbook.yml file."""
        ...

    def ansible_config_path(self) -> Path:
        """Get the path to the ansible.cfg file."""
        ...
