"""Tests for update command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestUpdateCommand:
    """Tests for the update command."""

    def test_update_help_shows_description(self, cli_runner: CliRunner) -> None:
        """Test that update --help shows description."""
        result = cli_runner.invoke(app, ["update", "--help"])

        assert result.exit_code == 0
        # Should mention update or version
        assert "update" in result.output.lower() or "version" in result.output.lower()

    def test_u_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'u' alias for update works."""
        result = cli_runner.invoke(app, ["u", "--help"])

        assert result.exit_code == 0
