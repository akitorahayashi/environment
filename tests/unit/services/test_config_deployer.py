"""Tests for ConfigDeployer service."""

from __future__ import annotations

from pathlib import Path

import pytest

from menv.services.config_deployer import ConfigDeployer
from tests.mocks import MockAnsiblePaths


class TestConfigDeployer:
    """Tests for the ConfigDeployer service."""

    @pytest.fixture
    def temp_home(self, tmp_path: Path) -> Path:
        """Create a temporary home directory."""
        home = tmp_path / "home"
        home.mkdir()
        return home

    @pytest.fixture
    def temp_ansible_dir(self, tmp_path: Path) -> Path:
        """Create a temporary ansible directory with role configs."""
        ansible_dir = tmp_path / "ansible"
        ansible_dir.mkdir()

        # Create a sample role config
        rust_config = ansible_dir / "roles" / "rust" / "config" / "common"
        rust_config.mkdir(parents=True)
        (rust_config / ".rust-version").write_text("1.75.0")
        (rust_config / "tools.yml").write_text("tools: []")

        # Create brew role with profiles
        brew_common = ansible_dir / "roles" / "brew" / "config" / "common" / "formulae"
        brew_common.mkdir(parents=True)
        (brew_common / "Brewfile").write_text("# Common Brewfile")

        brew_macbook = (
            ansible_dir / "roles" / "brew" / "config" / "profiles" / "macbook" / "cask"
        )
        brew_macbook.mkdir(parents=True)
        (brew_macbook / "Brewfile").write_text("# Macbook Brewfile")

        return ansible_dir

    @pytest.fixture
    def deployer(
        self, temp_ansible_dir: Path, temp_home: Path, monkeypatch: pytest.MonkeyPatch
    ) -> ConfigDeployer:
        """Create a ConfigDeployer with mocked paths."""
        monkeypatch.setattr(Path, "home", lambda: temp_home)
        mock_paths = MockAnsiblePaths(ansible_dir=temp_ansible_dir)
        return ConfigDeployer(ansible_paths=mock_paths)

    def test_list_roles_returns_roles_with_config_dirs(
        self, deployer: ConfigDeployer
    ) -> None:
        """Test that list_roles returns roles that have config directories."""
        roles = deployer.list_roles()

        # Should find the roles we set up in temp_ansible_dir fixture
        assert "rust" in roles
        assert "brew" in roles
        # Roles without config directories should not be included
        assert len(roles) == 2

    def test_get_local_config_path(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that local config path is correctly constructed."""
        path = deployer.get_local_config_path("rust")

        assert path == temp_home / ".config" / "menv" / "roles" / "rust"

    def test_get_package_config_path(
        self, deployer: ConfigDeployer, temp_ansible_dir: Path
    ) -> None:
        """Test that package config path is correctly constructed."""
        path = deployer.get_package_config_path("rust")

        assert path == temp_ansible_dir / "roles" / "rust" / "config"

    def test_is_deployed_returns_false_when_not_deployed(
        self, deployer: ConfigDeployer
    ) -> None:
        """Test that is_deployed returns False when config doesn't exist."""
        assert deployer.is_deployed("rust") is False

    def test_is_deployed_returns_true_after_deployment(
        self, deployer: ConfigDeployer
    ) -> None:
        """Test that is_deployed returns True after successful deployment."""
        deployer.deploy_role("rust")

        assert deployer.is_deployed("rust") is True

    def test_deploy_role_creates_config_directory(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_role creates the config directory."""
        result = deployer.deploy_role("rust")

        assert result.success is True
        assert "Deployed" in result.message
        expected_path = temp_home / ".config" / "menv" / "roles" / "rust"
        assert expected_path.exists()
        assert (expected_path / "common" / ".rust-version").exists()

    def test_deploy_role_copies_files(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_role copies config files correctly."""
        deployer.deploy_role("rust")

        rust_version_path = (
            temp_home
            / ".config"
            / "menv"
            / "roles"
            / "rust"
            / "common"
            / ".rust-version"
        )
        assert rust_version_path.read_text() == "1.75.0"

    def test_deploy_role_skips_if_exists_without_overlay(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_role skips deployment if config exists."""
        # First deployment
        deployer.deploy_role("rust")

        # Modify the local file
        local_file = (
            temp_home
            / ".config"
            / "menv"
            / "roles"
            / "rust"
            / "common"
            / ".rust-version"
        )
        local_file.write_text("1.80.0")

        # Second deployment without overlay
        result = deployer.deploy_role("rust", overlay=False)

        assert result.success is True
        assert "already exists" in result.message
        # File should not be overwritten
        assert local_file.read_text() == "1.80.0"

    def test_deploy_role_overwrites_with_overlay(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_role overwrites config with overlay flag."""
        # First deployment
        deployer.deploy_role("rust")

        # Modify the local file
        local_file = (
            temp_home
            / ".config"
            / "menv"
            / "roles"
            / "rust"
            / "common"
            / ".rust-version"
        )
        local_file.write_text("1.80.0")

        # Second deployment with overlay
        result = deployer.deploy_role("rust", overlay=True)

        assert result.success is True
        assert "Deployed" in result.message
        # File should be overwritten with original value
        assert local_file.read_text() == "1.75.0"

    def test_deploy_role_fails_for_invalid_role(self, deployer: ConfigDeployer) -> None:
        """Test that deploy_role fails for non-existent role."""
        result = deployer.deploy_role("nonexistent")

        assert result.success is False
        assert "does not have a config directory" in result.message

    def test_deploy_all_deploys_all_roles(self, deployer: ConfigDeployer) -> None:
        """Test that deploy_all deploys all roles."""
        results = deployer.deploy_all()

        # All results should have success=True (either deployed or not found in package)
        successful = [r for r in results if r.success]
        assert len(successful) >= 2  # At least rust and brew should succeed

    def test_deploy_role_fails_for_role_without_config_directory(
        self, deployer: ConfigDeployer
    ) -> None:
        """Test that deploy_role fails for a role without a config directory."""
        # python role has no config directory in our test setup
        result = deployer.deploy_role("python")

        assert result.success is False
        assert "does not have a config directory" in result.message


class TestDeployMultipleRoles:
    """Tests for the deploy_multiple_roles method."""

    @pytest.fixture
    def temp_home(self, tmp_path: Path) -> Path:
        """Create a temporary home directory."""
        home = tmp_path / "home"
        home.mkdir()
        return home

    @pytest.fixture
    def temp_ansible_dir(self, tmp_path: Path) -> Path:
        """Create a temporary ansible directory with role configs."""
        ansible_dir = tmp_path / "ansible"
        ansible_dir.mkdir()

        # Create rust role config
        rust_config = ansible_dir / "roles" / "rust" / "config" / "common"
        rust_config.mkdir(parents=True)
        (rust_config / ".rust-version").write_text("1.75.0")

        # Create shell role config
        shell_config = ansible_dir / "roles" / "shell" / "config" / "common"
        shell_config.mkdir(parents=True)
        (shell_config / ".zshrc").write_text("# zshrc")

        # Create go role config
        go_config = ansible_dir / "roles" / "go" / "config" / "common"
        go_config.mkdir(parents=True)
        (go_config / ".go-version").write_text("1.21.0")

        return ansible_dir

    @pytest.fixture
    def deployer(
        self, temp_ansible_dir: Path, temp_home: Path, monkeypatch: pytest.MonkeyPatch
    ) -> ConfigDeployer:
        """Create a ConfigDeployer with mocked paths."""
        monkeypatch.setattr(Path, "home", lambda: temp_home)
        mock_paths = MockAnsiblePaths(ansible_dir=temp_ansible_dir)
        return ConfigDeployer(ansible_paths=mock_paths)

    def test_deploy_multiple_roles_deploys_all_roles(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_multiple_roles deploys all specified roles."""
        results = deployer.deploy_multiple_roles(["rust", "shell", "go"])

        assert len(results) == 3
        assert all(r.success for r in results)

        # Check all configs were deployed
        assert (temp_home / ".config" / "menv" / "roles" / "rust").exists()
        assert (temp_home / ".config" / "menv" / "roles" / "shell").exists()
        assert (temp_home / ".config" / "menv" / "roles" / "go").exists()

    def test_deploy_multiple_roles_stops_on_first_failure(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_multiple_roles stops on first failure."""
        # Include an invalid role in the middle
        results = deployer.deploy_multiple_roles(["rust", "nonexistent", "shell"])

        # Should have 2 results: rust (success) and nonexistent (failure)
        assert len(results) == 2
        assert results[0].success is True
        assert results[0].role == "rust"
        assert results[1].success is False
        assert results[1].role == "nonexistent"

        # shell should NOT be deployed because we stopped early
        assert not (temp_home / ".config" / "menv" / "roles" / "shell").exists()

    def test_deploy_multiple_roles_empty_list(self, deployer: ConfigDeployer) -> None:
        """Test that deploy_multiple_roles with empty list returns empty results."""
        results = deployer.deploy_multiple_roles([])

        assert results == []

    def test_deploy_multiple_roles_with_overlay(
        self, deployer: ConfigDeployer, temp_home: Path
    ) -> None:
        """Test that deploy_multiple_roles respects overlay flag."""
        # First deployment
        deployer.deploy_multiple_roles(["rust"])

        # Modify local file
        local_file = (
            temp_home
            / ".config"
            / "menv"
            / "roles"
            / "rust"
            / "common"
            / ".rust-version"
        )
        local_file.write_text("modified")

        # Second deployment with overlay
        results = deployer.deploy_multiple_roles(["rust"], overlay=True)

        assert len(results) == 1
        assert results[0].success is True
        # File should be overwritten
        assert local_file.read_text() == "1.75.0"
