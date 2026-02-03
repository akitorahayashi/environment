"""Config deployment service implementation."""

from __future__ import annotations

import shutil
from functools import cached_property
from pathlib import Path
from typing import TYPE_CHECKING

from menv.protocols.config_deployer import DeployResult

if TYPE_CHECKING:
    from menv.protocols.ansible_paths import AnsiblePathsProtocol


class ConfigDeployer:
    """Deploy role configs from package to ~/.config/menv/."""

    def __init__(self, ansible_paths: AnsiblePathsProtocol) -> None:
        """Initialize ConfigDeployer.

        Args:
            ansible_paths: Path resolver for Ansible resources.
        """
        self._ansible_paths = ansible_paths
        self._local_config_root = Path.home() / ".config" / "menv" / "roles"

    @cached_property
    def roles_with_config(self) -> list[str]:
        """Dynamically find roles that have a 'config' directory.

        Returns:
            Sorted list of role names that have config directories.
        """
        roles_dir = self._ansible_paths.ansible_dir() / "roles"
        found_roles = []
        if roles_dir.is_dir():
            for role_path in roles_dir.iterdir():
                if role_path.is_dir() and (role_path / "config").is_dir():
                    found_roles.append(role_path.name)
        return sorted(found_roles)

    def deploy_role(self, role: str, overwrite: bool = False) -> DeployResult:
        """Deploy config for a single role to ~/.config/menv/roles/{role}/.

        Args:
            role: The role name to deploy.
            overwrite: If True, overwrite existing config.

        Returns:
            DeployResult with success status and message.
        """
        if role not in self.roles_with_config:
            return DeployResult(
                role=role,
                success=False,
                message=f"Role '{role}' does not have a config directory.",
            )

        package_config = self.get_package_config_path(role)
        if not package_config.exists():
            return DeployResult(
                role=role,
                success=False,
                message=f"Package config not found: {package_config}",
            )

        local_config = self.get_local_config_path(role)

        # Check if already deployed
        if local_config.exists() and not overwrite:
            return DeployResult(
                role=role,
                success=True,
                message="Config already exists (use --overwrite to overwrite).",
                path=local_config,
            )

        try:
            # Create parent directories
            local_config.parent.mkdir(parents=True, exist_ok=True)

            # Remove existing if overwrite
            if local_config.exists() and overwrite:
                shutil.rmtree(local_config)

            # Copy config directory
            shutil.copytree(package_config, local_config)
        except OSError as e:
            return DeployResult(
                role=role,
                success=False,
                message=f"Failed to deploy config: {e}",
            )

        return DeployResult(
            role=role,
            success=True,
            message=f"Deployed config to {local_config}",
            path=local_config,
        )

    def deploy_all(self, overwrite: bool = False) -> list[DeployResult]:
        """Deploy configs for all roles.

        Args:
            overwrite: If True, overwrite existing configs.

        Returns:
            List of DeployResult for each role.
        """
        results = []
        for role in self.roles_with_config:
            result = self.deploy_role(role, overwrite=overwrite)
            results.append(result)
        return results

    def get_local_config_path(self, role: str) -> Path:
        """Get the local config path for a role.

        Args:
            role: The role name.

        Returns:
            Path to ~/.config/menv/roles/{role}/.
        """
        return self._local_config_root / role

    def get_package_config_path(self, role: str) -> Path:
        """Get the package config path for a role.

        Args:
            role: The role name.

        Returns:
            Path to package ansible/roles/{role}/config/.
        """
        return self._ansible_paths.ansible_dir() / "roles" / role / "config"

    def is_deployed(self, role: str) -> bool:
        """Check if a role's config is already deployed.

        Args:
            role: The role name.

        Returns:
            True if config exists at local path.
        """
        return self.get_local_config_path(role).exists()

    def list_roles(self) -> list[str]:
        """List all available roles with configs.

        Returns:
            List of role names that have config directories.
        """
        return list(self.roles_with_config)

    def deploy_multiple_roles(
        self, roles: list[str], overwrite: bool = False
    ) -> list[DeployResult]:
        """Deploy configs for multiple roles, stopping on first failure.

        Args:
            roles: List of role names to deploy.
            overwrite: If True, overwrite existing configs.

        Returns:
            List of DeployResult for each role attempted.
            Stops early if any deployment fails.
        """
        results = []
        for role in roles:
            result = self.deploy_role(role, overwrite=overwrite)
            results.append(result)
            if not result.success:
                break
        return results
