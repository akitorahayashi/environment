from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def gh_config_dir(project_root: Path) -> Path:
    """Path to the GitHub CLI configuration directory."""
    return project_root / "ansible/roles/gh/config/common"


@pytest.fixture(scope="session")
def gh_pr_ls_script_path(gh_config_dir: Path) -> Path:
    """Path to the gh-pr-ls.py script."""
    return gh_config_dir.parent.parent / "scripts" / "gh-pr-ls.py"