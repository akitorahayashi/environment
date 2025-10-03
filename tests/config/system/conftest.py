from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def system_config_dir(project_root: Path) -> Path:
    """Path to the system configuration directory."""
    return project_root / "ansible/roles/system/config/common"
