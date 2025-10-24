from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def rust_config_dir(project_root: Path) -> Path:
    """Return the directory containing shared Rust configuration files."""
    return project_root / "ansible/roles/rust/config/common"


__all__ = [
    "rust_config_dir",
]
