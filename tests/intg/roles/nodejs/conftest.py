from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def nodejs_coder_config_base(project_root: Path) -> Path:
    """Base directory for Node.js coder configuration."""
    return project_root / "src/menv/ansible/roles/nodejs/config/common/coder"


@pytest.fixture(scope="session")
def nodejs_coder_skills_root(nodejs_coder_config_base: Path) -> Path:
    """Root directory containing shared agent skills."""
    return nodejs_coder_config_base / "skills"


@pytest.fixture(scope="session")
def nodejs_coder_skills_targets_path(nodejs_coder_config_base: Path) -> Path:
    """Path to the skills targets configuration file."""
    return nodejs_coder_config_base / "skills-targets.yml"


__all__ = [
    "nodejs_coder_config_base",
    "nodejs_coder_skills_root",
    "nodejs_coder_skills_targets_path",
]
