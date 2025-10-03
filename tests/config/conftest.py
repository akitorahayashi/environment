from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def editor_config_dirs(project_root: Path) -> dict[str, Path]:
    """Mapping of editor identifiers to their configuration directories."""
    return {
        "vscode": project_root / "ansible/roles/vscode/config/common",
        "cursor": project_root / "ansible/roles/cursor/config/common",
    }


__all__ = [
    "editor_config_dirs",
]
