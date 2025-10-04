from __future__ import annotations

import os
import shutil
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
    """Path to the gm_mcp_ln.py script."""
    return shell_config_dir.parent.parent / "scripts" / "gm_mcp_ln.py"


@pytest.fixture(autouse=True)
def ensure_pbcopy(
    monkeypatch: pytest.MonkeyPatch, tmp_path_factory: pytest.TempPathFactory
) -> None:
    """Provide a pbcopy stub on systems where it is unavailable."""

    if shutil.which("pbcopy"):
        return

    bin_dir = tmp_path_factory.mktemp("pbcopy-bin")
    pbcopy = bin_dir / "pbcopy"
    pbcopy.write_text(
        "#!/usr/bin/env python3\n"
        "import sys\n"
        "# Emulate macOS pbcopy by consuming stdin and exiting successfully.\n"
        "sys.stdin.read()\n"
    )
    pbcopy.chmod(0o755)

    existing_path = os.environ.get("PATH", "")
    monkeypatch.setenv("PATH", f"{bin_dir}:{existing_path}")
