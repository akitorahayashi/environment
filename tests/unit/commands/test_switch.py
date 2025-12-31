"""Tests for switch command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestSwitchCommand:
    """Tests for the switch command."""

    def test_switch_help_shows_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that switch --help shows profile argument."""
        result = cli_runner.invoke(app, ["switch", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_sw_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'sw' alias for switch works."""
        result = cli_runner.invoke(app, ["sw", "--help"])

        assert result.exit_code == 0
        assert "PROFILE" in result.output or "profile" in result.output.lower()

    def test_switch_invalid_profile_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid switch profile shows error."""
        result = cli_runner.invoke(app, ["switch", "invalid-profile"])

        assert result.exit_code != 0
        assert "Invalid profile" in result.output or "Error" in result.output

    def test_switch_requires_profile_argument(self, cli_runner: CliRunner) -> None:
        """Test that switch without profile shows error."""
        result = cli_runner.invoke(app, ["switch"])

        # Should show error about missing argument
        assert result.exit_code != 0 or "PROFILE" in result.output
