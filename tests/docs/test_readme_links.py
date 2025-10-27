"""Tests for documentation integrity."""

from __future__ import annotations

import re
from pathlib import Path

import pytest


@pytest.fixture(scope="module")
def readme_content(project_root: Path) -> str:
    """Read the README.md file."""
    readme_path = project_root / "README.md"
    return readme_path.read_text(encoding="utf-8")


@pytest.fixture(scope="module")
def docs_dir(project_root: Path) -> Path:
    """Path to the docs directory."""
    return project_root / "docs"


def extract_markdown_links(content: str) -> list[str]:
    """Extract all Markdown links from content."""
    # Match [text](url) patterns
    link_pattern = re.compile(r'\[([^\]]+)\]\(([^)]+)\)')
    links = []
    for match in link_pattern.finditer(content):
        url = match.group(2)
        links.append(url)
    return links


def test_readme_docs_links_exist(readme_content: str, docs_dir: Path) -> None:
    """Test that all docs/ links in README.md point to existing files."""
    links = extract_markdown_links(readme_content)
    
    # Filter links that start with ./docs/
    docs_links = [link for link in links if link.startswith('./docs/')]
    
    missing_files = []
    for link in docs_links:
        # Remove the ./docs/ prefix and any anchor (#...)
        relative_path = link.replace('./docs/', '').split('#')[0]
        if relative_path.endswith('/'):
            # If it ends with /, it's a directory, but we expect files
            continue
        file_path = docs_dir / relative_path
        if not file_path.exists():
            missing_files.append(str(file_path))
    
    assert not missing_files, f"Missing documentation files: {missing_files}"