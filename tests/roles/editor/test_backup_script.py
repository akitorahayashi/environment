import importlib.util
from pathlib import Path
from types import ModuleType

import pytest


@pytest.fixture()
def backup_extensions_module(project_root: Path) -> ModuleType:
    script_path = project_root / "ansible/scripts/editor/backup-extensions.py"
    spec = importlib.util.spec_from_file_location("backup_extensions", script_path)
    if spec is None:
        raise RuntimeError(f"Could not load spec from {script_path}")
    if spec.loader is None:
        raise RuntimeError(f"Spec loader is None for {script_path}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_backup_extensions_main_success(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
    backup_extensions_module: ModuleType,
) -> None:
    config_dir = tmp_path / "config"
    config_dir.mkdir()

    monkeypatch.setattr(backup_extensions_module, "detect_command", lambda: "code")
    monkeypatch.setattr(
        backup_extensions_module,
        "list_extensions",
        lambda command: ["ext.one", "ext.two"],
    )

    exit_code = backup_extensions_module.main([str(config_dir)])
    assert exit_code == 0

    output_path = config_dir / "vscode-extensions.json"
    data = output_path.read_text(encoding="utf-8")
    assert "ext.one" in data
    assert "ext.two" in data
