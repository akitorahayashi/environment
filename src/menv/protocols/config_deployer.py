"""Protocol for config deployment operations."""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Protocol


@dataclass
class DeployResult:
    """Result of a config deployment operation."""

    role: str
    success: bool
    message: str
    path: Path | None = None


class ConfigDeployerProtocol(Protocol):
    """Config deployment abstraction."""

    @property
    def roles_with_config(self) -> list[str]:
        """Get list of roles that have config directories.

        Returns:
            Sorted list of role names that have config directories.
        """
        ...

    def deploy_role(self, role: str, overlay: bool = False) -> DeployResult:
        """Deploy config for a single role to ~/.config/menv/roles/{role}/.

        Args:
            role: The role name to deploy.
            overlay: If True, overwrite existing config.

        Returns:
            DeployResult with success status and message.
        """
        ...

    def deploy_all(self, overlay: bool = False) -> list[DeployResult]:
        """Deploy configs for all roles.

        Args:
            overlay: If True, overwrite existing configs.

        Returns:
            List of DeployResult for each role.
        """
        ...

    def get_local_config_path(self, role: str) -> Path:
        """Get the local config path for a role.

        Args:
            role: The role name.

        Returns:
            Path to ~/.config/menv/roles/{role}/.
        """
        ...

    def get_package_config_path(self, role: str) -> Path:
        """Get the package config path for a role.

        Args:
            role: The role name.

        Returns:
            Path to package ansible/roles/{role}/config/.
        """
        ...

    def is_deployed(self, role: str) -> bool:
        """Check if a role's config is already deployed.

        Args:
            role: The role name.

        Returns:
            True if config exists at local path.
        """
        ...

    def list_roles(self) -> list[str]:
        """List all available roles with configs.

        Returns:
            List of role names that have config directories.
        """
        ...
