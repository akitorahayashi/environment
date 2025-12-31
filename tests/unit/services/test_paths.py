"""Tests for path resolution utilities."""

from __future__ import annotations

from pathlib import Path


class TestPathResolution:
    """Tests for the paths module."""

    def test_get_ansible_dir_returns_path(self) -> None:
        """Test that get_ansible_dir returns a valid path."""
        from menv.services.ansible_paths import AnsiblePaths

        paths = AnsiblePaths()
        result = paths.ansible_dir()
        assert isinstance(result, Path)
        assert result.name == "ansible"

    def test_get_playbook_path_exists(self) -> None:
        """Test that get_playbook_path returns path to existing file."""
        from menv.services.ansible_paths import AnsiblePaths

        paths = AnsiblePaths()
        result = paths.playbook_path()
        assert isinstance(result, Path)
        assert result.name == "playbook.yml"
        assert result.exists()

    def test_get_ansible_config_path_exists(self) -> None:
        """Test that get_ansible_config_path returns path to existing file."""
        from menv.services.ansible_paths import AnsiblePaths

        paths = AnsiblePaths()
        result = paths.ansible_config_path()
        assert isinstance(result, Path)
        assert result.name == "ansible.cfg"
        assert result.exists()

    def test_playbook_is_in_ansible_dir(self) -> None:
        """Test that playbook is located within ansible directory."""
        from menv.services.ansible_paths import AnsiblePaths

        paths = AnsiblePaths()
        ansible_dir = paths.ansible_dir()
        playbook_path = paths.playbook_path()
        assert playbook_path.parent == ansible_dir
