from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def go_config_dir(project_root: Path) -> Path:
    """Return the directory containing shared Go configuration files."""
    return project_root / "src/menv/ansible/roles/go/config/common"


__all__ = [
    "go_config_dir",
]
