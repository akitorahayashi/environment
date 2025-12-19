import glob
import os
from pathlib import Path

import pytest
import yaml


@pytest.fixture(scope="session")
def definitions_path(system_config_dir: Path) -> Path:
    """Path to the system definitions directory."""
    return system_config_dir / "definitions/"


@pytest.fixture(scope="session")
def yml_files(definitions_path: Path) -> list[str]:
    """Discover all .yml files in the target directory to be used in tests."""
    return glob.glob(os.path.join(definitions_path, "*.yml"))


class TestSystemDefinitions:
    def test_definitions(self, yml_files: list[str]) -> None:
        """
        Verify syntax and schema for all system definition .yml files.
        """
        if not yml_files:
            pytest.skip("No .yml definition files found to test.")

        for yaml_file_path in yml_files:
            file_basename = os.path.basename(yaml_file_path)
            with open(yaml_file_path, "r") as f:
                try:
                    data = yaml.safe_load(f)
                except yaml.YAMLError as e:
                    pytest.fail(f"Invalid YAML syntax in {file_basename}: {e}")

            if data is None:
                # Skip empty files, they are valid but have no schema to check
                continue

            definitions = data if isinstance(data, list) else [data]
            required_keys = ["key", "domain", "type", "default"]

            for i, definition in enumerate(definitions):
                assert isinstance(
                    definition,
                    dict,
                ), f"Definition #{i + 1} in {file_basename} is not a dictionary."
                for key in required_keys:
                    assert key in definition, (
                        f"Missing required key '{key}' in definition #{i + 1} in {file_basename}."
                    )
