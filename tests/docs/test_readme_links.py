"""Tests for documentation integrity."""

from __future__ import annotations

import re
from pathlib import Path


def extract_markdown_links(content: str) -> list[str]:
    """Extract all Markdown links from content."""
    # Match [text](url) patterns
    link_pattern = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
    return link_pattern.findall(content)


def test_all_markdown_links_are_valid(project_root: Path):
    """Test that all relative links in all markdown files point to existing files."""
    # Find all .md files, excluding those in .venv and other irrelevant directories
    exclude_patterns = [".venv", "__pycache__", ".git", ".pytest_cache", "node_modules"]

    markdown_files = []
    for md_file in project_root.rglob("*.md"):
        if any(excl in str(md_file) for excl in exclude_patterns):
            continue
        markdown_files.append(md_file)

    all_missing_links = {}

    for md_file in markdown_files:
        content = md_file.read_text(encoding="utf-8")
        links = extract_markdown_links(content)

        # Filter for relative links (not starting with http or just an anchor)
        relative_links = [link for link in links if not link.startswith(("http", "#"))]

        missing_in_file = []
        for link in relative_links:
            # Remove anchor from link
            link_path_str = link.split("#")[0]
            if not link_path_str:
                continue

            # Build absolute path for the linked file
            target_path = (md_file.parent / Path(link_path_str)).resolve()

            # Check if the file exists as a file
            if not target_path.is_file():
                missing_in_file.append(link)

        if missing_in_file:
            all_missing_links[str(md_file.relative_to(project_root))] = missing_in_file

    assert (
        not all_missing_links
    ), f"Found broken links in documentation: {all_missing_links}"
