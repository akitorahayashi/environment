"""Mock PlaybookService implementation."""

from __future__ import annotations

from menv.protocols.playbook import PlaybookServiceProtocol


class MockPlaybookService(PlaybookServiceProtocol):
    """In-memory mock playbook service for testing."""

    def __init__(
        self,
        tags_map: dict[str, list[str]] | None = None,
    ) -> None:
        """Initialize mock with optional custom tags map.

        Args:
            tags_map: Optional custom role→tags mapping.
                      If not provided, uses a default set.
        """
        self._tags_map = tags_map or {
            "brew": ["brew-formulae", "brew-cask"],
            "python": ["python-platform", "python-tools", "aider", "uv"],
            "nodejs": ["nodejs-platform", "nodejs-tools", "llm"],
            "ruby": ["ruby"],
            "rust": ["rust-platform", "rust-tools"],
            "go": ["go-platform", "go-tools"],
            "vcs": ["git", "jj"],
            "gh": ["gh"],
            "shell": ["shell"],
            "ssh": ["ssh"],
            "editor": ["editor", "vscode", "cursor", "xcode"],
            "coderabbit": ["coderabbit"],
            "system": ["system"],
            "docker": ["docker"],
        }

        # Build reverse mapping
        self._tag_to_role: dict[str, str] = {}
        for role, tags in self._tags_map.items():
            for tag in tags:
                self._tag_to_role[tag] = role

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
