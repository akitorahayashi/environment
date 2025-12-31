"""Mock ConfigDeployer implementation."""

from __future__ import annotations

from pathlib import Path

from menv.protocols.config_deployer import ConfigDeployerProtocol, DeployResult


class MockConfigDeployer(ConfigDeployerProtocol):
    """In-memory mock config deployer for testing."""

    def __init__(
        self,
        deployed_roles: set[str] | None = None,
        roles_with_config: list[str] | None = None,
    ) -> None:
        """Initialize mock with optional pre-deployed roles.

        Args:
            deployed_roles: Set of role names that are already deployed.
            roles_with_config: List of roles with config directories.
        """
        self._deployed_roles: set[str] = deployed_roles or set()
        self._roles_with_config = roles_with_config or [
            "brew",
            "docker",
            "editor",
            "gh",
            "go",
            "nodejs",
            "python",
            "ruby",
            "rust",
            "shell",
            "ssh",
            "system",
            "vcs",
        ]
        self._local_config_root = Path("/mock/.config/menv/roles")
        self._package_config_root = Path("/mock/ansible/roles")

    @property
    def roles_with_config(self) -> list[str]:
        """Return list of roles with config directories."""
        return self._roles_with_config

    def deploy_role(self, role: str, overlay: bool = False) -> DeployResult:
        """Mock deploy config for a single role.

        Args:
            role: The role name to deploy.
            overlay: If True, overwrite existing config.

        Returns:
            DeployResult with success status and message.
        """
        if role not in self.roles_with_config:
            return DeployResult(
                role=role,
                success=False,
                message=f"Role '{role}' does not have a config directory.",
            )

        local_path = self.get_local_config_path(role)

        if role in self._deployed_roles and not overlay:
            return DeployResult(
                role=role,
                success=True,
                message="Config already exists (use --overlay to overwrite).",
                path=local_path,
            )

        self._deployed_roles.add(role)
        return DeployResult(
            role=role,
            success=True,
            message=f"Deployed config to {local_path}",
            path=local_path,
        )

    def deploy_all(self, overlay: bool = False) -> list[DeployResult]:
        """Mock deploy configs for all roles.

        Args:
            overlay: If True, overwrite existing configs.

        Returns:
            List of DeployResult for each role.
        """
        results = []
        for role in self.roles_with_config:
            result = self.deploy_role(role, overlay=overlay)
            results.append(result)
        return results

    def get_local_config_path(self, role: str) -> Path:
        """Get the local config path for a role.

        Args:
            role: The role name.

        Returns:
            Path to mock local config.
        """
        return self._local_config_root / role

    def get_package_config_path(self, role: str) -> Path:
        """Get the package config path for a role.

        Args:
            role: The role name.

        Returns:
            Path to mock package config.
        """
        return self._package_config_root / role / "config"

    def is_deployed(self, role: str) -> bool:
        """Check if a role's config is already deployed.

        Args:
            role: The role name.

        Returns:
            True if role is in deployed set.
        """
        return role in self._deployed_roles

    def list_roles(self) -> list[str]:
        """List all available roles with configs.

        Returns:
            List of role names.
        """
        return list(self.roles_with_config)
