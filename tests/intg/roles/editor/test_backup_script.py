from pathlib import Path

import pytest

from menv.commands.backup.services.vscode_extensions import (
    run,
)


def test_backup_extensions_main_success(
    tmp_path: Path,
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    config_dir = tmp_path / "config"
    config_dir.mkdir()

    import menv.commands.backup.services.vscode_extensions as mod

    monkeypatch.setattr(mod, "detect_command", lambda: "code")
    monkeypatch.setattr(
        mod,
        "list_extensions",
        lambda command: ["ext.one", "ext.two"],
    )

    exit_code = run(config_dir)
    assert exit_code == 0

    output_path = config_dir / "vscode-extensions.json"
    data = output_path.read_text(encoding="utf-8")
    assert "ext.one" in data
    assert "ext.two" in data
