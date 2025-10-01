"""Global fixtures and helpers for the test suite."""

from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def project_root() -> Path:
    """Absolute path to the repository root."""
    return Path(__file__).resolve().parent.parent


@pytest.fixture(scope="session")
def workspace(tmp_path_factory: pytest.TempPathFactory) -> Path:
    """Create a unique temporary directory for each test session.

    This fixture provides a common workspace for tests that need temporary
    file operations, eliminating code duplication across test files.

    Args:
        tmp_path_factory: pytest's built-in temporary path factory

    Returns:
        Path object of the created temporary directory
    """
    return tmp_path_factory.mktemp("test_workspace")


@pytest.fixture(scope="session")
def config_dir_abs_path(project_root: Path) -> Path:
    """Resolved absolute path for the common configuration directory."""
    return project_root / "config" / "common"


@pytest.fixture(scope="session")
def profile_config_path(project_root: Path):
    """Factory fixture for profile-specific configuration paths."""
    def _profile_config_path(profile: str) -> Path:
        return project_root / "config" / "profiles" / profile
    return _profile_config_path