from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def llm_config_dir(project_root: Path) -> Path:
    """Return the directory containing shared LLM configuration files."""
    return project_root / "src/menv/ansible/roles/llm/config"


@pytest.fixture(scope="session")
def llm_common_config_dir(llm_config_dir: Path) -> Path:
    """Return the common LLM configuration directory."""
    return llm_config_dir / "common"


@pytest.fixture(scope="session")
def llm_profiles_config_dir(llm_config_dir: Path) -> Path:
    """Return the profiles LLM configuration directory."""
    return llm_config_dir / "profiles"


__all__ = [
    "llm_config_dir",
    "llm_common_config_dir",
    "llm_profiles_config_dir",
]
