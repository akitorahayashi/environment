"""Tests for version management utilities."""

from __future__ import annotations

from unittest.mock import MagicMock, patch


class TestVersionManagement:
    """Tests for the version module."""

    def test_get_current_version_returns_string(self) -> None:
        """Test that get_current_version returns a version string."""
        from menv.services.version_checker import VersionChecker

        result = VersionChecker().get_current_version()
        assert isinstance(result, str)
        # Should match semver pattern or be fallback
        assert result.count(".") >= 1

    def test_get_current_version_fallback_on_not_found(self) -> None:
        """Test fallback when package is not found."""
        from menv.services.version_checker import VersionChecker

        with patch("menv.services.version_checker.metadata.version") as mock_version:
            from importlib.metadata import PackageNotFoundError

            mock_version.side_effect = PackageNotFoundError("menv")
            result = VersionChecker().get_current_version()
            assert result == "0.0.0"

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

    def test_needs_update_handles_invalid_versions(self) -> None:
        """Test needs_update handles invalid version strings."""
        from menv.services.version_checker import VersionChecker

        # Should return False for invalid versions
        checker = VersionChecker()
        assert checker.needs_update("invalid", "0.1.0") is False
        assert checker.needs_update("0.1.0", "invalid") is False

    def test_get_latest_version_returns_none_on_network_error(self) -> None:
        """Test get_latest_version returns None when network fails."""
        from menv.services.version_checker import VersionChecker

        with patch("menv.services.version_checker.httpx.get") as mock_get:
            import httpx

            mock_get.side_effect = httpx.HTTPError("Network error")
            result = VersionChecker().get_latest_version()
            assert result is None

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

    def test_run_pipx_upgrade_handles_oserror(self) -> None:
        """Test that run_pipx_upgrade handles generic OSError."""
        from menv.services.version_checker import VersionChecker

        mock_console = MagicMock()
        checker = VersionChecker(console=mock_console)
        with patch(
            "menv.services.version_checker.subprocess.run",
            side_effect=OSError("Exec format error"),
        ):
            result = checker.run_pipx_upgrade()
            # Should return a non-zero exit code (e.g. 1) instead of crashing
            assert result == 1
            # Verify error message was printed
            mock_console.print.assert_called_with(
                "[bold red]Error:[/] Failed to run pipx: Exec format error"
            )
