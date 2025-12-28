"""Tests for installer checksums to ensure security of downloaded scripts."""

from __future__ import annotations

import hashlib
from pathlib import Path

import httpx
import pytest
import yaml


@pytest.fixture(scope="session")
def installer_checksums(project_root: Path) -> list[dict[str, str]]:
    """Load installer checksums from YAML file."""
    checksums_file = project_root / "tests/intg/installer_checksums.yml"
    with open(checksums_file, encoding="utf-8") as f:
        data = yaml.safe_load(f)
    return data["installer_checksums"]


class TestInstallerChecksums:
    """Test checksums for external installer scripts."""

    def test_installer_checksums(
        self,
        installer_checksums: list[dict[str, str]],
    ) -> None:
        """Test that installer scripts match expected SHA256 checksums."""
        for installer in installer_checksums:
            url = installer["url"]
            expected_checksum = installer["checksum"]

            with httpx.Client() as client:
                response = client.get(url)
                response.raise_for_status()

            content = response.content

            # Calculate SHA256
            sha256 = hashlib.sha256(content).hexdigest()
            full_checksum = f"sha256:{sha256}"

            assert full_checksum == expected_checksum, (
                f"Checksum mismatch for {url}.\n"
                f"Expected: {expected_checksum}\n"
                f"Actual:   {full_checksum}"
            )
