from pathlib import Path

import pytest
import yaml


@pytest.fixture(scope="session")
def xcode_config_path(editor_config_base: Path) -> Path:
    """Path to the Xcode configuration directory."""
    return editor_config_base / "xcode"


@pytest.fixture(scope="session")
def xcode_yml_files(xcode_config_path: Path) -> list[Path]:
    """Discover all .yml files in the Xcode config directory."""
    return list(xcode_config_path.glob("*.yml"))


class TestXcodeConfigs:
    def test_xcode_definitions(self, xcode_yml_files: list[Path]) -> None:
        """
        Verify syntax and schema for all Xcode definition .yml files.
        """
        if not xcode_yml_files:
            pytest.fail("No Xcode .yml config files found to test.")

        for yaml_file_path in xcode_yml_files:
            file_basename = yaml_file_path.name
            with yaml_file_path.open("r") as f:
                try:
                    data = yaml.safe_load(f)
                except yaml.YAMLError as e:
                    pytest.fail(f"Invalid YAML syntax in {file_basename}: {e}")

            if data is None:
                # Skip empty files
                continue

            definitions = data if isinstance(data, list) else [data]
            required_keys = ["key", "domain", "type", "value"]

            for i, definition in enumerate(definitions):
                assert isinstance(
                    definition,
                    dict,
                ), f"Definition #{i+1} in {file_basename} is not a dictionary."

                for key in required_keys:
                    assert (
                        key in definition
                    ), f"Missing required key '{key}' in definition #{i+1} in {file_basename}."

                # Verify type validity
                valid_types = ["bool", "int", "string", "float"]
                assert (
                    definition["type"] in valid_types
                ), f"Invalid type '{definition['type']}' in definition #{i+1} in {file_basename}. Must be one of {valid_types}."
