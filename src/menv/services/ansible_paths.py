"""Path resolution for package-internal Ansible resources."""

from __future__ import annotations

from importlib.resources import as_file, files
from pathlib import Path
from typing import Any

from menv.protocols.ansible_paths import AnsiblePathsProtocol


class AnsiblePaths(AnsiblePathsProtocol):
    """Resolve package-internal Ansible paths.

    For pipx/pip wheel installations, files() returns paths directly from
    site-packages. The as_file context manager ensures compatibility with
    all installation methods, including zip archives.
    """

    def __init__(self) -> None:
        # Cache the context manager to keep the temporary path alive
        self._ansible_dir_context: Any = None
        self._ansible_dir: Path | None = None

    def ansible_dir(self) -> Path:
        """Get the path to the ansible directory within the package.

        The first call enters the as_file context manager and caches both
        the context and the path. Subsequent calls return the cached path.
        The context remains alive for the lifetime of this service instance.
        """
        if self._ansible_dir is not None:
            return self._ansible_dir

        source = files("menv").joinpath("ansible")
        # Enter the context and keep it alive by storing it
        self._ansible_dir_context = as_file(source)
        self._ansible_dir = Path(self._ansible_dir_context.__enter__())

        return self._ansible_dir

    def __del__(self) -> None:
        """Clean up the context manager on deletion."""
        if self._ansible_dir_context is not None:
            self._ansible_dir_context.__exit__(None, None, None)

    def playbook_path(self) -> Path:
        """Get the path to the main playbook.yml file."""
        return self.ansible_dir() / "playbook.yml"

    def ansible_config_path(self) -> Path:
        """Get the path to ansible.cfg configuration file."""
        return self.ansible_dir() / "ansible.cfg"
