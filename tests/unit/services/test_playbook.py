"""Tests for Playbook."""

from __future__ import annotations

from pathlib import Path
from textwrap import dedent

import pytest

from menv.services.playbook import Playbook
from tests.mocks import MockAnsiblePaths


class TestPlaybook:
    """Tests for the Playbook service."""

    @pytest.fixture
    def temp_ansible_dir(self, tmp_path: Path) -> Path:
        """Create a temporary ansible directory with a valid playbook."""
        ansible_dir = tmp_path / "ansible"
        ansible_dir.mkdir()

        playbook_content = dedent(
            """\
            ---
            - name: Setup macOS development environment
              hosts: localhost
              connection: local
              roles:
                - { role: brew, tags: ["brew-formulae", "brew-cask"] }
                - { role: python, tags: ["python-platform", "python-tools"] }
                - { role: rust, tags: ["rust-platform", "rust-tools"] }
                - { role: shell, tags: ["shell"] }
            """
        )
        (ansible_dir / "playbook.yml").write_text(playbook_content)

        return ansible_dir

    @pytest.fixture
    def playbook(self, temp_ansible_dir: Path) -> Playbook:
        """Create a Playbook with mocked paths."""
        mock_paths = MockAnsiblePaths(ansible_dir=temp_ansible_dir)
        return Playbook(ansible_paths=mock_paths)

    def test_get_tags_map_returns_role_to_tags_mapping(
        self, playbook: Playbook
    ) -> None:
        """Test that get_tags_map returns correct role→tags mapping."""
        tags_map = playbook.get_tags_map()

        assert "brew" in tags_map
        assert tags_map["brew"] == ["brew-formulae", "brew-cask"]
        assert "python" in tags_map
        assert tags_map["python"] == ["python-platform", "python-tools"]
        assert "rust" in tags_map
        assert tags_map["rust"] == ["rust-platform", "rust-tools"]
        assert "shell" in tags_map
        assert tags_map["shell"] == ["shell"]

    def test_get_all_tags_returns_sorted_list(self, playbook: Playbook) -> None:
        """Test that get_all_tags returns all tags sorted."""
        all_tags = playbook.get_all_tags()

        # Should contain all tags from the playbook
        expected_tags = [
            "brew-cask",
            "brew-formulae",
            "python-platform",
            "python-tools",
            "rust-platform",
            "rust-tools",
            "shell",
        ]
        assert all_tags == expected_tags

    def test_get_role_for_tag_returns_correct_role(self, playbook: Playbook) -> None:
        """Test that get_role_for_tag returns the correct role."""
        assert playbook.get_role_for_tag("brew-formulae") == "brew"
        assert playbook.get_role_for_tag("brew-cask") == "brew"
        assert playbook.get_role_for_tag("python-platform") == "python"
        assert playbook.get_role_for_tag("rust-tools") == "rust"
        assert playbook.get_role_for_tag("shell") == "shell"

    def test_get_role_for_tag_returns_none_for_unknown_tag(
        self, playbook: Playbook
    ) -> None:
        """Test that get_role_for_tag returns None for unknown tags."""
        assert playbook.get_role_for_tag("unknown-tag") is None
        assert playbook.get_role_for_tag("") is None

    def test_validate_tags_returns_true_for_valid_tags(
        self, playbook: Playbook
    ) -> None:
        """Test that validate_tags returns True for valid tags."""
        assert playbook.validate_tags(["brew-formulae", "shell"]) is True
        assert playbook.validate_tags(["rust-platform", "rust-tools"]) is True
        assert playbook.validate_tags([]) is True  # Empty list is valid

    def test_validate_tags_returns_false_for_invalid_tags(
        self, playbook: Playbook
    ) -> None:
        """Test that validate_tags returns False for invalid tags."""
        assert playbook.validate_tags(["unknown-tag"]) is False
        assert playbook.validate_tags(["shell", "unknown-tag"]) is False

    def test_playbook_data_is_cached(self, playbook: Playbook) -> None:
        """Test that playbook data is cached after first access."""
        # Access tags_map twice
        tags_map1 = playbook.get_tags_map()
        tags_map2 = playbook.get_tags_map()

        # Should be equal (same cached data)
        assert tags_map1 == tags_map2

    def test_handles_roles_without_tags(self, tmp_path: Path) -> None:
        """Test that roles without tags are handled correctly."""
        ansible_dir = tmp_path / "ansible"
        ansible_dir.mkdir()

        playbook_content = dedent(
            """\
            ---
            - name: Test playbook
              hosts: localhost
              roles:
                - simple_role
                - { role: tagged_role, tags: ["tag1"] }
            """
        )
        (ansible_dir / "playbook.yml").write_text(playbook_content)

        mock_paths = MockAnsiblePaths(ansible_dir=ansible_dir)
        service = Playbook(ansible_paths=mock_paths)

        tags_map = service.get_tags_map()

        # simple_role should have empty tags list
        assert tags_map.get("simple_role") == []
        # tagged_role should have its tags
        assert tags_map.get("tagged_role") == ["tag1"]
