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


@pytest.fixture(scope="session")
def mcp_config_dir(project_root: Path) -> Path:
    """Path to the MCP configuration directory."""
    return project_root / "ansible/roles/mcp/config/common"


@pytest.fixture(scope="session")
def runtime_config_dirs(project_root: Path) -> dict[str, Path]:
    """Mapping of runtime names to their configuration directories."""
    return {
        "python": project_root / "ansible/roles/python/config/common",
        "ruby": project_root / "ansible/roles/ruby/config/common",
        "nodejs": project_root / "ansible/roles/nodejs/config/common",
    }


@pytest.fixture(scope="session")
def system_config_dir(project_root: Path) -> Path:
    """Path to the system configuration directory."""
    return project_root / "ansible/roles/system/config/common"


@pytest.fixture(scope="session")
def slash_config_dir(project_root: Path) -> Path:
    """Path to the slash configuration directory."""
    return project_root / "ansible/roles/slash/config/common"


__all__ = [
    "editor_config_dirs",
    "mcp_config_dir",
    "runtime_config_dirs",
    "system_config_dir",
    "slash_config_dir",
]
