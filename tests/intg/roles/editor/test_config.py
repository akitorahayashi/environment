import json
from pathlib import Path
from typing import Dict

import pytest


@pytest.fixture(scope="session")
def editor_config_files(editor_config_base: Path) -> Dict[str, Path]:
    """Known editor configuration files within the shared editor role."""
    return {
        "settings": editor_config_base / "settings.json",
        "keybindings": editor_config_base / "keybindings.json",
        "vscode_extensions": editor_config_base / "vscode-extensions.json",
        "cursor_extensions": editor_config_base / "cursor-extensions.json",
        "antigravity_extensions": editor_config_base / "antigravity-extensions.json",
    }


@pytest.fixture(scope="session")
def existing_config_files(editor_config_files: Dict[str, Path]) -> Dict[str, Path]:
    """Filter for files that actually exist to avoid test failures on missing files."""
    return {name: path for name, path in editor_config_files.items() if path.exists()}


@pytest.fixture(scope="session")
def extensions_files(existing_config_files: Dict[str, Path]) -> Dict[str, Path]:
    """Filter for extension definition files."""
    return {
        name: path
        for name, path in existing_config_files.items()
        if name.endswith("_extensions")
    }


class TestEditorConfigs:
    def test_editor_config_json_syntax(
        self, existing_config_files: Dict[str, Path]
    ) -> None:
        """Verify that all editor configuration files have valid JSON syntax."""
        if not existing_config_files:
            pytest.skip("No editor config files found to test.")

        for name, config_path in existing_config_files.items():
            with config_path.open("r") as f:
                try:
                    json.load(f)
                except json.JSONDecodeError as e:
                    pytest.fail(f"Invalid JSON syntax in {name}: {e}")

    def test_extensions_json_schema(self, extensions_files: Dict[str, Path]) -> None:
        """Verify that extension definition files expose the expected schema."""
        if not extensions_files:
            pytest.skip("No extension definition files found to test.")

        for name, extensions_path in extensions_files.items():
            with extensions_path.open("r") as f:
                try:
                    data = json.load(f)
                except json.JSONDecodeError as e:
                    pytest.fail(f"Invalid JSON in {name}: {e}")

            assert isinstance(data, dict), f"{name} should be a JSON object."
            assert "extensions" in data, f"Missing 'extensions' key in {name}."

            extensions_list = data["extensions"]
            assert isinstance(extensions_list, list), (
                f"'extensions' value in {name} should be a list."
            )

            for item in extensions_list:
                assert isinstance(item, str), (
                    f"All items in the 'extensions' list in {name} should be strings."
                )
