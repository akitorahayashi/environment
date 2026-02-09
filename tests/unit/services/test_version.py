"""Tests for version management utilities."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from menv.exceptions import VersionCheckError


class TestVersionManagement:
    """Tests for the version module."""

    def test_get_current_version_returns_string(self) -> None:
        """Test that get_current_version returns a version string."""
        from menv.services.version_checker import VersionChecker

        result = VersionChecker().get_current_version()
        assert isinstance(result, str)
        # Should match semver pattern or be fallback
        assert result.count(".") >= 1

    def test_get_current_version_raises_on_not_found(self) -> None:
        """Test raises when package is not found."""
        from menv.services.version_checker import VersionChecker

        with patch("menv.services.version_checker.metadata.version") as mock_version:
            from importlib.metadata import PackageNotFoundError

            mock_version.side_effect = PackageNotFoundError("menv")
            with pytest.raises(VersionCheckError, match="package not found"):
                VersionChecker().get_current_version()

    def test_needs_update_returns_true_when_newer(self) -> None:
        """Test needs_update returns True when latest > current."""
        from menv.services.version_checker import VersionChecker

        checker = VersionChecker()
        assert checker.needs_update("0.1.0", "0.2.0") is True
        assert checker.needs_update("0.1.0", "1.0.0") is True
        assert checker.needs_update("1.0.0", "1.0.1") is True

    def test_needs_update_returns_false_when_same_or_older(self) -> None:
        """Test needs_update returns False when current >= latest."""
        from menv.services.version_checker import VersionChecker

        checker = VersionChecker()
        assert checker.needs_update("0.2.0", "0.1.0") is False
        assert checker.needs_update("0.1.0", "0.1.0") is False
        assert checker.needs_update("1.0.0", "0.9.0") is False

    def test_needs_update_raises_on_invalid_versions(self) -> None:
        """Test needs_update raises on invalid version strings."""
        from menv.services.version_checker import VersionChecker

        # Should raise VersionCheckError for invalid versions
        checker = VersionChecker()
        with pytest.raises(VersionCheckError, match="Invalid version comparison"):
            checker.needs_update("invalid", "0.1.0")
        with pytest.raises(VersionCheckError, match="Invalid version comparison"):
            checker.needs_update("0.1.0", "invalid")

    def test_get_latest_version_raises_on_network_error(self) -> None:
        """Test get_latest_version raises when network fails."""
        from menv.services.version_checker import VersionChecker

        with patch("menv.services.version_checker.httpx.get") as mock_get:
            import httpx

            mock_get.side_effect = httpx.HTTPError("Network error")
            with pytest.raises(VersionCheckError, match="Failed to fetch"):
                VersionChecker().get_latest_version()

    def test_get_latest_version_strips_v_prefix(self) -> None:
        """Test get_latest_version removes 'v' prefix from tag."""
        from menv.services.version_checker import VersionChecker

        with patch("menv.services.version_checker.httpx.get") as mock_get:
            mock_response = MagicMock()
            mock_response.json.return_value = {"tag_name": "v0.2.0"}
            mock_response.raise_for_status = MagicMock()
            mock_get.return_value = mock_response

            result = VersionChecker().get_latest_version()
            assert result == "0.2.0"

    def test_get_latest_version_raises_on_invalid_data(self) -> None:
        """Test get_latest_version raises on invalid JSON or missing tag."""
        from menv.services.version_checker import VersionChecker

        with patch("menv.services.version_checker.httpx.get") as mock_get:
            mock_response = MagicMock()
            mock_response.raise_for_status = MagicMock()

            # Case 1: missing tag_name
            mock_response.json.return_value = {}
            mock_get.return_value = mock_response
            with pytest.raises(VersionCheckError, match="No tag name found"):
                VersionChecker().get_latest_version()

            # Case 2: malformed json (ValueError from .json())
            mock_response.json.side_effect = ValueError("Invalid JSON")
            with pytest.raises(VersionCheckError, match="Failed to parse release data"):
                VersionChecker().get_latest_version()

    def test_run_pipx_upgrade_raises_on_oserror(self) -> None:
        """Test that run_pipx_upgrade raises on generic OSError."""
        from menv.services.version_checker import VersionChecker

        mock_console = MagicMock()
        checker = VersionChecker(console=mock_console)
        with patch(
            "menv.services.version_checker.subprocess.run",
            side_effect=OSError("Exec format error"),
        ):
            with pytest.raises(VersionCheckError, match="Failed to run pipx"):
                checker.run_pipx_upgrade()
            # Verify error message was printed
            mock_console.print.assert_called()

    def test_run_pipx_upgrade_failure(self) -> None:
        """Test that run_pipx_upgrade raises on non-zero exit code."""
        from menv.services.version_checker import VersionChecker

        checker = VersionChecker(console=MagicMock())
        with patch("menv.services.version_checker.subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=1)
            with pytest.raises(VersionCheckError, match="pipx upgrade failed"):
                checker.run_pipx_upgrade()

    def test_run_pipx_upgrade_not_found(self) -> None:
        """Test that run_pipx_upgrade raises when pipx is not found."""
        from menv.services.version_checker import VersionChecker

        checker = VersionChecker(console=MagicMock())
        with patch("menv.services.version_checker.subprocess.run") as mock_run:
            mock_run.side_effect = FileNotFoundError("No such file")
            with pytest.raises(VersionCheckError, match="pipx not found"):
                checker.run_pipx_upgrade()
