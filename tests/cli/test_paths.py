"""Tests for path resolution utilities."""

from __future__ import annotations

from pathlib import Path


class TestPathResolution:
    """Tests for the paths module."""

    def test_get_ansible_dir_returns_path(self) -> None:
        """Test that get_ansible_dir returns a valid path."""
        from menv.paths import get_ansible_dir

        result = get_ansible_dir()
        assert isinstance(result, Path)
        assert result.name == "ansible"

    def test_get_playbook_path_exists(self) -> None:
        """Test that get_playbook_path returns path to existing file."""
        from menv.paths import get_playbook_path

        result = get_playbook_path()
        assert isinstance(result, Path)
        assert result.name == "playbook.yml"
        assert result.exists()

    def test_get_ansible_config_path_exists(self) -> None:
        """Test that get_ansible_config_path returns path to existing file."""
        from menv.paths import get_ansible_config_path

        result = get_ansible_config_path()
        assert isinstance(result, Path)
        assert result.name == "ansible.cfg"
        assert result.exists()

    def test_playbook_is_in_ansible_dir(self) -> None:
        """Test that playbook is located within ansible directory."""
        from menv.paths import get_ansible_dir, get_playbook_path

        ansible_dir = get_ansible_dir()
        playbook_path = get_playbook_path()
        assert playbook_path.parent == ansible_dir
