import importlib.util
import sys
import textwrap
from pathlib import Path
from types import ModuleType

import pytest


@pytest.fixture()
def backup_system_module(project_root: Path) -> ModuleType:
    script_path = project_root / "ansible/scripts/system/backup-system.py"
    spec = importlib.util.spec_from_file_location("backup_system", script_path)
    if spec is None:
        raise RuntimeError(f"Could not load spec from {script_path}")
    if spec.loader is None:
        raise RuntimeError(f"Spec loader is None for {script_path}")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def test_backup_system_writes_expected_yaml(
    monkeypatch: pytest.MonkeyPatch,
    tmp_path: Path,
    backup_system_module: ModuleType,
) -> None:
    definitions_dir = tmp_path / "definitions"
    definitions_dir.mkdir()
    definitions_dir.joinpath("sample.yml").write_text(
        textwrap.dedent(
            """
            ---
            - key: SampleBool
              domain: NSGlobalDomain
              type: bool
              default: true
              comment: "Sample"
            - key: location
              domain: com.apple.screencapture
              type: string
              default: "$HOME/Desktop"
            - key: SampleInt
              domain: custom.domain
              type: int
              default: 2
            """
        ),
        encoding="utf-8",
    )

    output_file = tmp_path / "system.yml"
    monkeypatch.setenv("HOME", "/Users/test")

    values = {
        ("NSGlobalDomain", "SampleBool"): "false",
        ("com.apple.screencapture", "location"): "/Users/test/Pictures",
        ("custom.domain", "SampleInt"): "7",
    }

    def fake_run_defaults(domain: str, key: str, default: object) -> str:
        return values.get((domain, key), str(default))

    monkeypatch.setattr(backup_system_module, "_run_defaults", fake_run_defaults)

    backup_system_module.backup_settings(definitions_dir, output_file)

    output = output_file.read_text(encoding="utf-8")
    assert '- { key: "SampleBool", type: "bool", value: false }' in output
    assert (
        '- { key: "location", domain: "com.apple.screencapture", type: "string", value: "$HOME/Pictures" }'
        in output
    )
    assert (
        '- { key: "SampleInt", domain: "custom.domain", type: "int", value: 7 }'
        in output
    )
