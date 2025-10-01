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
