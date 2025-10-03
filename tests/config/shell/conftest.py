from __future__ import annotations

from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def shell_config_dir(project_root: Path) -> Path:
    """Path to the shell configuration directory."""
    return project_root / "ansible/roles/shell/config/common"


@pytest.fixture(scope="session")
def gen_gemini_aliases_script_path(shell_config_dir: Path) -> Path:
    """Path to the gen_gemini_aliases.py script."""
    return shell_config_dir.parent.parent / "scripts" / "gen_gemini_aliases.py"


@pytest.fixture(scope="session")
def mcp_script_path(shell_config_dir: Path) -> Path:
    """Path to the mcp.py script."""
    return shell_config_dir.parent.parent / "scripts" / "mcp.py"


@pytest.fixture(scope="session")
def gm_mcp_script_path(shell_config_dir: Path) -> Path:
    """Path to the gm-mcp-ln.py script."""
    return shell_config_dir.parent.parent / "scripts" / "gm-mcp-ln.py"