"""Playbook service implementation."""

from __future__ import annotations

from functools import cached_property
from typing import TYPE_CHECKING

import yaml

if TYPE_CHECKING:
    from menv.protocols.ansible_paths import AnsiblePathsProtocol


class Playbook:
    """Service for parsing and querying playbook.yml.

    This service makes playbook.yml the Single Source of Truth (SSOT)
    for all tag and role information, eliminating hardcoded constants.
    """

    def __init__(self, ansible_paths: AnsiblePathsProtocol) -> None:
        """Initialize Playbook.

        Args:
            ansible_paths: Path resolver for Ansible resources.
        """
        self._ansible_paths = ansible_paths

    @cached_property
    def _playbook_data(self) -> list[dict]:
        """Load and cache the playbook YAML data.

        Returns:
            Parsed YAML data from playbook.yml.

        Raises:
            FileNotFoundError: If playbook.yml doesn't exist.
            yaml.YAMLError: If playbook.yml is invalid YAML.
        """
        playbook_path = self._ansible_paths.playbook_path()
        with playbook_path.open() as f:
            return yaml.safe_load(f)

    @cached_property
    def _tags_map(self) -> dict[str, list[str]]:
        """Parse the playbook and build role→tags mapping.

        Returns:
            Dictionary mapping role names to lists of tags.
        """
        tags_map: dict[str, list[str]] = {}

        for play in self._playbook_data:
            if "roles" not in play:
                continue

            for role_entry in play["roles"]:
                # Handle both dict format { role: name, tags: [...] }
                # and simple string format "role_name"
                if isinstance(role_entry, dict):
                    role_name = role_entry.get("role")
                    tags = role_entry.get("tags", [])
                    if role_name:
                        tags_map[role_name] = list(tags)
                elif isinstance(role_entry, str):
                    # Simple role reference without tags
                    tags_map[role_entry] = []

        return tags_map

    @cached_property
    def _tag_to_role(self) -> dict[str, str]:
        """Build reverse mapping from tag→role.

        Returns:
            Dictionary mapping tag names to role names.
        """
        tag_to_role: dict[str, str] = {}
        for role, tags in self._tags_map.items():
            for tag in tags:
                tag_to_role[tag] = role
        return tag_to_role

    def get_tags_map(self) -> dict[str, list[str]]:
        """Get mapping of roles to their tags.

        Returns:
            Dictionary mapping role names to lists of tags.
        """
        return dict(self._tags_map)

    def get_all_tags(self) -> list[str]:
        """Get all available tags from the playbook.

        Returns:
            Sorted list of all tag names.
        """
        all_tags: set[str] = set()
        for tags in self._tags_map.values():
            all_tags.update(tags)
        return sorted(all_tags)

    def get_role_for_tag(self, tag: str) -> str | None:
        """Get the role name for a given tag.

        Args:
            tag: The tag name to look up.

        Returns:
            The role name if found, None otherwise.
        """
        return self._tag_to_role.get(tag)

    def validate_tags(self, tags: list[str]) -> bool:
        """Validate that all provided tags exist in the playbook.

        Args:
            tags: List of tag names to validate.

        Returns:
            True if all tags are valid, False otherwise.
        """
        all_tags = set(self.get_all_tags())
        return all(tag in all_tags for tag in tags)
