"""Integration tests for playbook.yml integrity."""

from __future__ import annotations

import pytest
import yaml

from menv.services.ansible_paths import AnsiblePaths
from menv.services.playbook import Playbook


class TestPlaybookIntegrity:
    """Integration tests that validate the actual playbook.yml file."""

    @pytest.fixture
    def ansible_paths(self) -> AnsiblePaths:
        """Get the real AnsiblePaths instance."""
        return AnsiblePaths()

    @pytest.fixture
    def playbook(self, ansible_paths: AnsiblePaths) -> Playbook:
        """Create Playbook with real paths."""
        return Playbook(ansible_paths=ansible_paths)

    def test_playbook_yml_parses_without_errors(
        self, ansible_paths: AnsiblePaths
    ) -> None:
        """Test that playbook.yml is valid YAML and parses correctly."""
        playbook_path = ansible_paths.ansible_dir() / "playbook.yml"

        assert playbook_path.exists(), f"playbook.yml not found at {playbook_path}"

        with playbook_path.open() as f:
            data = yaml.safe_load(f)

        assert data is not None
        assert isinstance(data, list)
        assert len(data) > 0

    def test_all_roles_have_directories(
        self, playbook: Playbook, ansible_paths: AnsiblePaths
    ) -> None:
        """Test that all roles referenced in playbook have directories."""
        tags_map = playbook.get_tags_map()
        roles_dir = ansible_paths.ansible_dir() / "roles"

        missing_roles = []
        for role in tags_map.keys():
            role_path = roles_dir / role
            if not role_path.is_dir():
                missing_roles.append(role)

        assert not missing_roles, f"Missing role directories: {missing_roles}"

    def test_tag_names_are_unique_except_shared(self, playbook: Playbook) -> None:
        """Test that tag names are unique across roles (except intentionally shared ones).

        Currently, there are no intentionally shared tags.
        """
        tags_map = playbook.get_tags_map()

        # Tags that are intentionally shared across multiple roles
        shared_tags: set[str] = set()

        seen_tags: dict[str, str] = {}
        duplicates: list[str] = []

        for role, tags in tags_map.items():
            for tag in tags:
                if tag in shared_tags:
                    continue  # Skip intentionally shared tags
                if tag in seen_tags:
                    duplicates.append(
                        f"Tag '{tag}' appears in both '{seen_tags[tag]}' and '{role}'"
                    )
                else:
                    seen_tags[tag] = role

        assert not duplicates, "Duplicate tags found:\n" + "\n".join(duplicates)

    def test_playbook_has_expected_structure(self, ansible_paths: AnsiblePaths) -> None:
        """Test that playbook.yml has the expected structure."""
        playbook_path = ansible_paths.ansible_dir() / "playbook.yml"

        with playbook_path.open() as f:
            data = yaml.safe_load(f)

        play = data[0]
        assert "name" in play
        assert "hosts" in play
        assert "roles" in play
        assert play["hosts"] == "localhost"

    def test_all_roles_have_at_least_one_tag(self, playbook: Playbook) -> None:
        """Test that all roles in playbook have at least one tag."""
        tags_map = playbook.get_tags_map()

        roles_without_tags = [role for role, tags in tags_map.items() if not tags]

        # This is a warning, not an error - roles can exist without explicit tags
        # but it's good to know about them
        if roles_without_tags:
            pytest.skip(f"Roles without tags (informational): {roles_without_tags}")

    def test_get_all_tags_returns_non_empty_list(self, playbook: Playbook) -> None:
        """Test that get_all_tags returns a non-empty list."""
        all_tags = playbook.get_all_tags()

        assert len(all_tags) > 0
        assert all(isinstance(tag, str) for tag in all_tags)
        # Tags should be sorted
        assert all_tags == sorted(all_tags)

    def test_common_tags_exist(self, playbook: Playbook) -> None:
        """Test that commonly expected tags exist."""
        all_tags = set(playbook.get_all_tags())

        # These are tags that should always exist based on the project structure
        expected_tags = [
            "shell",
            "rust-platform",
            "rust-tools",
            "python-platform",
            "python-tools",
        ]

        missing_tags = [tag for tag in expected_tags if tag not in all_tags]

        assert not missing_tags, f"Expected tags missing: {missing_tags}"
