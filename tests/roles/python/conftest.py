from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def python_config_dir(project_root: Path) -> Path:
    """Return the directory containing shared Python configuration files."""
    return project_root / "src/menv/ansible/roles/python/config/common"


__all__ = [
    "python_config_dir",
]
