"""Tests for menv.internal_binary.locator."""

from __future__ import annotations

import stat
from pathlib import Path
from unittest.mock import patch

import pytest

from menv.internal_binary import locator


class TestPlatformKey:
    def test_returns_lowercase_system_and_machine(self) -> None:
        with (
            patch("platform.system", return_value="Darwin"),
            patch("platform.machine", return_value="x86_64"),
        ):
            assert locator._platform_key() == "darwin-x86_64"

    def test_normalizes_arm64_to_aarch64(self) -> None:
        with (
            patch("platform.system", return_value="Darwin"),
            patch("platform.machine", return_value="arm64"),
        ):
            assert locator._platform_key() == "darwin-aarch64"

    def test_linux_platform(self) -> None:
        with (
            patch("platform.system", return_value="Linux"),
            patch("platform.machine", return_value="x86_64"),
        ):
            assert locator._platform_key() == "linux-x86_64"


class TestLocate:
    def test_raises_file_not_found_when_binary_missing(self, tmp_path: Path) -> None:
        with patch.object(locator, "_bundled_binaries_root", return_value=tmp_path):
            with pytest.raises(FileNotFoundError, match="not found"):
                locator.locate()

    def test_raises_permission_error_when_not_executable(self, tmp_path: Path) -> None:
        key = locator._platform_key()
        binary_dir = tmp_path / key
        binary_dir.mkdir(parents=True)
        binary = binary_dir / "menv-internal"
        binary.write_text("fake")
        binary.chmod(stat.S_IRUSR)

        with patch.object(locator, "_bundled_binaries_root", return_value=tmp_path):
            with pytest.raises(PermissionError, match="not executable"):
                locator.locate()

    def test_returns_path_when_valid(self, tmp_path: Path) -> None:
        key = locator._platform_key()
        binary_dir = tmp_path / key
        binary_dir.mkdir(parents=True)
        binary = binary_dir / "menv-internal"
        binary.write_text("fake")
        binary.chmod(stat.S_IRUSR | stat.S_IXUSR)

        with patch.object(locator, "_bundled_binaries_root", return_value=tmp_path):
            result = locator.locate()
            assert result == binary


class TestIsAvailable:
    def test_returns_false_when_binary_missing(self, tmp_path: Path) -> None:
        with patch.object(locator, "_bundled_binaries_root", return_value=tmp_path):
            assert locator.is_available() is False

    def test_returns_true_when_binary_valid(self, tmp_path: Path) -> None:
        key = locator._platform_key()
        binary_dir = tmp_path / key
        binary_dir.mkdir(parents=True)
        binary = binary_dir / "menv-internal"
        binary.write_text("fake")
        binary.chmod(stat.S_IRUSR | stat.S_IXUSR)

        with patch.object(locator, "_bundled_binaries_root", return_value=tmp_path):
            assert locator.is_available() is True
