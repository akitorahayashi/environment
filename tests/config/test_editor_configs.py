import json
from pathlib import Path
from typing import Dict

import pytest


@pytest.fixture(scope="session")
def config_files_to_check(editor_config_dirs: Dict[str, Path]) -> list[Path]:
    """List all potential configuration files to be tested."""
    return [
        editor_config_dirs["vscode"] / "settings.json",
        editor_config_dirs["vscode"] / "keybindings.json",
        editor_config_dirs["vscode"] / "extensions.json",
        editor_config_dirs["cursor"] / "extensions.json",
        editor_config_dirs["cursor"] / "settings.json",
        editor_config_dirs["cursor"] / "keybindings.json",
    ]


@pytest.fixture(scope="session")
def existing_config_files(config_files_to_check: list[Path]) -> list[Path]:
    """Filter for files that actually exist to avoid test failures on missing files."""
    return [p for p in config_files_to_check if p.exists()]


@pytest.fixture(scope="session")
def extensions_files(existing_config_files: list[Path]) -> list[Path]:
    """Filter for extensions.json files."""
    return [p for p in existing_config_files if "extensions.json" in p.name]


def _create_test_id(path: Path, editor_config_dirs: Dict[str, Path]) -> str:
    """Create a shorter, more readable test ID from the file path."""
    for name, base_dir in editor_config_dirs.items():
        if base_dir in path.parents or path == base_dir:
            relative = path.relative_to(base_dir)
            return f"{name}/{relative}"
    return str(path)


class TestEditorConfigs:
    def test_editor_config_json_syntax(
        self, existing_config_files: list[Path], editor_config_dirs: Dict[str, Path]
    ) -> None:
        """Verify that all editor configuration files have valid JSON syntax."""
        if not existing_config_files:
            pytest.skip("No editor config files found to test.")

        for config_path in existing_config_files:
            with config_path.open("r") as f:
                try:
                    json.load(f)
                except json.JSONDecodeError as e:
                    pytest.fail(
                        f"Invalid JSON syntax in {_create_test_id(config_path, editor_config_dirs)}: {e}"
                    )

    def test_extensions_json_schema(
        self, extensions_files: list[Path], editor_config_dirs: Dict[str, Path]
    ) -> None:
        """
        Verify that extensions.json files have the correct schema:
        an object with an 'extensions' key holding a list of strings.
        """
        if not extensions_files:
            pytest.skip("No extensions.json files found to test.")

        for extensions_path in extensions_files:
            with extensions_path.open("r") as f:
                try:
                    data = json.load(f)
                except json.JSONDecodeError as e:
                    # This case is covered by the syntax test, but fail here to be explicit.
                    pytest.fail(
                        f"Invalid JSON in {_create_test_id(extensions_path, editor_config_dirs)}: {e}"
                    )

            assert isinstance(
                data, dict
            ), f"{_create_test_id(extensions_path, editor_config_dirs)} should be a JSON object."
            assert (
                "extensions" in data
            ), f"Missing 'extensions' key in {_create_test_id(extensions_path, editor_config_dirs)}."

            extensions_list = data["extensions"]
            assert isinstance(
                extensions_list,
                list,
            ), f"'extensions' value in {_create_test_id(extensions_path, editor_config_dirs)} should be a list."

            for item in extensions_list:
                assert isinstance(
                    item,
                    str,
                ), f"All items in the 'extensions' list in {_create_test_id(extensions_path, editor_config_dirs)} should be strings."
