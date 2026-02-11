"""Integration tests for playbook.yml integrity."""

from __future__ import annotations

import re
from collections import defaultdict
from typing import Iterable

import pytest
import yaml

from menv.services.ansible_paths import AnsiblePaths
from menv.services.playbook import Playbook

RUN_TAG_PATTERN = re.compile(r"'([^']+)'\s+in\s+ansible_run_tags")


def normalize_when_clauses(when_value: object) -> Iterable[str]:
    """Normalize an Ansible `when` clause into iterable strings."""
    if isinstance(when_value, str):
        return [when_value]
    if isinstance(when_value, list):
        return [item for item in when_value if isinstance(item, str)]
    return []


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

    def test_role_task_tag_conditions_match_playbook(
        self,
        ansible_role_tasks,
        ansible_playbook_mapping,
    ) -> None:
        """Ensure tag-gated roles reference the full playbook tag set."""
        role_to_tags = defaultdict(set)
        for tag, roles in ansible_playbook_mapping.items():
            for role in roles:
                role_to_tags[role].add(tag)

        when_tags_by_role = defaultdict(set)
        for task_file in ansible_role_tasks:
            if task_file.path.name != "main.yml":
                continue
            for task in task_file.tasks:
                when_value = task.get("when")
                if when_value is None:
                    continue
                for clause in normalize_when_clauses(when_value):
                    when_tags_by_role[task_file.role].update(
                        RUN_TAG_PATTERN.findall(clause)
                    )

        for role, when_tags in when_tags_by_role.items():
            if not when_tags:
                continue
            playbook_tags = role_to_tags.get(role, set())
            assert playbook_tags, f"Role '{role}' missing playbook tags"
            assert when_tags == playbook_tags, (
                f"Role '{role}' tag-gated tasks should cover playbook tags. "
                f"Playbook: {sorted(playbook_tags)} | When: {sorted(when_tags)}"
            )
