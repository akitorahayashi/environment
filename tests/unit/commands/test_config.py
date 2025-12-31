"""Tests for config command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestConfigCommand:
    """Tests for the config command."""

    def test_config_help_shows_action_argument(self, cli_runner: CliRunner) -> None:
        """Test that config --help shows action argument."""
        result = cli_runner.invoke(app, ["config", "--help"])

        assert result.exit_code == 0
        assert "ACTION" in result.output or "action" in result.output.lower()

    def test_cf_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'cf' alias for config works."""
        result = cli_runner.invoke(app, ["cf", "--help"])

        assert result.exit_code == 0
        assert "ACTION" in result.output or "action" in result.output.lower()

    def test_config_invalid_action_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid config action shows error."""
        result = cli_runner.invoke(app, ["config", "invalid-action"])

        assert result.exit_code != 0
        assert "Unknown action" in result.output or "Error" in result.output
