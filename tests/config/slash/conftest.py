from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def slash_config_dir(project_root: Path) -> Path:
    """Path to the slash configuration directory."""
    return project_root / "ansible/roles/slash/config/common"
