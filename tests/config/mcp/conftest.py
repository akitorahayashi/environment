from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def mcp_config_dir(project_root: Path) -> Path:
    """Path to the MCP configuration directory."""
    return project_root / "ansible/roles/mcp/config/common"