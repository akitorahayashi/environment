"""Tests for backup command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestBackupCommand:
    """Tests for the backup command."""

    def test_backup_help_shows_target_argument(self, cli_runner: CliRunner) -> None:
        """Test that backup --help shows target argument."""
        result = cli_runner.invoke(app, ["backup", "--help"])

        assert result.exit_code == 0
        assert "TARGET" in result.output or "target" in result.output.lower()

    def test_bk_alias_works(self, cli_runner: CliRunner) -> None:
        """Test that 'bk' alias for backup works."""
        result = cli_runner.invoke(app, ["bk", "--help"])

        assert result.exit_code == 0
        assert "TARGET" in result.output or "target" in result.output.lower()

    def test_backup_list_shows_targets(self, cli_runner: CliRunner) -> None:
        """Test that backup list shows available targets."""
        result = cli_runner.invoke(app, ["backup", "list"])

        assert result.exit_code == 0
        assert "system" in result.output.lower() or "vscode" in result.output.lower()

    def test_backup_invalid_target_shows_error(self, cli_runner: CliRunner) -> None:
        """Test that invalid backup target shows error."""
        result = cli_runner.invoke(app, ["backup", "invalid-target"])

        assert result.exit_code != 0
        assert "Unknown backup target" in result.output or "Error" in result.output
