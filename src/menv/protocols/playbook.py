"""Protocol for playbook service."""

from __future__ import annotations

from typing import Protocol


class PlaybookServiceProtocol(Protocol):
    """Playbook service abstraction for parsing and querying playbook.yml."""

    def get_tags_map(self) -> dict[str, list[str]]:
        """Get mapping of roles to their tags.

        Returns:
            Dictionary mapping role names to lists of tags.
        """
        ...

    def get_all_tags(self) -> list[str]:
        """Get all available tags from the playbook.

        Returns:
            Sorted list of all tag names.
        """
        ...

    def get_role_for_tag(self, tag: str) -> str | None:
        """Get the role name for a given tag.

        Args:
            tag: The tag name to look up.

        Returns:
            The role name if found, None otherwise.
        """
        ...

    def validate_tags(self, tags: list[str]) -> bool:
        """Validate that all provided tags exist in the playbook.

        Args:
            tags: List of tag names to validate.

        Returns:
            True if all tags are valid, False otherwise.
        """
        ...
