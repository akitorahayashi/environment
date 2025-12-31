from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def editor_config_base(project_root: Path) -> Path:
    """Base directory containing shared editor configuration files."""
    return project_root / "src/menv/ansible/roles/editor/config/common"


__all__ = [
    "editor_config_base",
]
