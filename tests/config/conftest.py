"""Fixtures and helpers local to the config test suite."""

from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def editor_config_dir(config_dir_abs_path: Path) -> Path:
    """Path to the editor configuration directory."""
    return config_dir_abs_path / "editor"


@pytest.fixture(scope="session")
def mcp_config_dir(config_dir_abs_path: Path) -> Path:
    """Path to the MCP configuration directory."""
    return config_dir_abs_path / "mcp"


@pytest.fixture(scope="session")
def runtime_config_dir(config_dir_abs_path: Path) -> Path:
    """Path to the runtime configuration directory."""
    return config_dir_abs_path / "runtime"


@pytest.fixture(scope="session")
def system_config_dir(config_dir_abs_path: Path) -> Path:
    """Path to the system configuration directory."""
    return config_dir_abs_path / "system"


@pytest.fixture(scope="session")
def slash_config_dir(config_dir_abs_path: Path) -> Path:
    """Path to the slash configuration directory."""
    return config_dir_abs_path / "slash"


__all__ = [
    "editor_config_dir",
    "mcp_config_dir",
    "runtime_config_dir",
    "system_config_dir",
    "slash_config_dir",
]
