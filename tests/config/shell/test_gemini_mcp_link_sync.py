from __future__ import annotations

import importlib.util
import json
from pathlib import Path
from types import ModuleType

import pytest


@pytest.fixture(scope="session")
def gm_mcp_script_path(shell_config_dir: Path) -> Path:
    """Path to the gm_mcp_ln.py script."""
    return shell_config_dir.parent.parent / "scripts" / "gm_mcp_ln.py"


@pytest.fixture(scope="module")
def gm_mcp_module(gm_mcp_script_path: Path) -> ModuleType:
    spec = importlib.util.spec_from_file_location("gm_mcp_ln", gm_mcp_script_path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_sync_mcp_servers_updates_settings(
    tmp_path: Path, gm_mcp_module: ModuleType
) -> None:
    project_root = tmp_path
    mcp_data = {"mcpServers": {"alpha": {"url": "http://alpha"}}}
    (project_root / ".mcp.json").write_text(json.dumps(mcp_data), encoding="utf-8")

    workdir = project_root / "workspace"
    workdir.mkdir()
    settings_path = workdir / ".gemini" / "settings.json"
    settings_path.parent.mkdir(parents=True)
    settings_path.write_text(json.dumps({"existing": True}), encoding="utf-8")

    servers, _ = gm_mcp_module.sync_mcp_servers(workdir)
    assert servers == mcp_data["mcpServers"]

    updated = json.loads(settings_path.read_text(encoding="utf-8"))
    assert updated["mcpServers"] == mcp_data["mcpServers"]
    assert updated["existing"] is True


def test_sync_mcp_servers_creates_settings(
    tmp_path: Path, gm_mcp_module: ModuleType
) -> None:
    project_root = tmp_path
    (project_root / ".mcp.json").write_text(
        json.dumps({"mcpServers": {}}), encoding="utf-8"
    )

    workdir = project_root / "nested" / "dir"
    workdir.mkdir(parents=True)

    servers, _ = gm_mcp_module.sync_mcp_servers(workdir)
    settings_path = workdir / ".gemini" / "settings.json"
    assert settings_path.exists()
    saved = json.loads(settings_path.read_text(encoding="utf-8"))
    assert saved["mcpServers"] == {}
    assert servers == {}


def test_sync_mcp_servers_missing_root(
    tmp_path: Path, gm_mcp_module: ModuleType
) -> None:
    workdir = tmp_path / "no-root"
    workdir.mkdir()
    with pytest.raises(FileNotFoundError):
        gm_mcp_module.sync_mcp_servers(workdir)


def test_sync_mcp_servers_invalid_settings(
    tmp_path: Path, gm_mcp_module: ModuleType
) -> None:
    project_root = tmp_path
    (project_root / ".mcp.json").write_text(
        json.dumps({"mcpServers": {}}), encoding="utf-8"
    )

    workdir = project_root / "workspace"
    workdir.mkdir()
    settings_path = workdir / ".gemini" / "settings.json"
    settings_path.parent.mkdir(parents=True)
    settings_path.write_text("not-json", encoding="utf-8")

    with pytest.raises(ValueError):
        gm_mcp_module.sync_mcp_servers(workdir)
