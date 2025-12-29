from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def gh_config_dir(project_root: Path) -> Path:
    """Path to the GitHub CLI configuration directory."""
    return project_root / "src/menv/ansible/roles/gh/config/common"


@pytest.fixture(scope="session")
def gh_pr_ls_script_path(project_root: Path) -> Path:
    """Path to the gh_pr_ls.py script."""
    return project_root / "src/menv/ansible/scripts/gh/gh_pr_ls.py"
