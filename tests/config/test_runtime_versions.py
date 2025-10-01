import re
from pathlib import Path

import pytest


@pytest.fixture(scope="session")
def version_files(runtime_config_dir: Path) -> list[Path]:
    """Define the relative paths to the version files."""
    return [
        runtime_config_dir / "python/.python-version",
        runtime_config_dir / "ruby/.ruby-version",
        runtime_config_dir / "nodejs/.nvmrc",
    ]


@pytest.fixture(scope="session")
def existing_files(version_files: list[Path]) -> dict[str, Path]:
    """Filter for files that actually exist to prevent test errors."""
    return {path.name: path for path in version_files if path.exists()}


class TestRuntimeVersions:
    def test_runtime_version_format(self, existing_files: dict[str, Path]) -> None:
        """
        Verify that runtime version files contain a version string in a valid format.
        """
        if not existing_files:
            pytest.skip("No runtime version files found to test.")

        for name, path in existing_files.items():
            with path.open("r") as f:
                version_string = f.read().strip()

            # This regex matches semantic versions, optionally prefixed with 'v'.
            # It handles formats like '1.2.3', 'v18.17.0', and also just '3.3'.
            version_pattern = re.compile(r"^v?(\d+\.\d+(\.\d+)?)$")

            assert version_pattern.match(version_string), (
                f"Invalid version format in {name}: '{version_string}'. "
                f"Expected a format like 'major.minor.patch'."
            )
