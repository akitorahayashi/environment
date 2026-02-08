"""Tests for backup command execution."""

from __future__ import annotations

from unittest.mock import patch

from typer.testing import CliRunner

from menv.main import app


class TestBackupExecution:
    """Tests for the backup command execution."""

    @patch("menv.commands.backup.services.system.run", return_value=0)
    def test_backup_system_calls_service(self, mock_run, cli_runner: CliRunner) -> None:
        """Test that backup system calls the system service run function."""
        result = cli_runner.invoke(app, ["backup", "system"])

        assert result.exit_code == 0
        mock_run.assert_called_once()
        kwargs = mock_run.call_args.kwargs
        assert "common" in str(kwargs["config_dir"])

    @patch("menv.commands.backup.services.vscode_extensions.run", return_value=0)
    def test_backup_vscode_calls_service(self, mock_run, cli_runner: CliRunner) -> None:
        """Test that backup vscode calls the vscode extensions service."""
        result = cli_runner.invoke(app, ["backup", "vscode"])

        assert result.exit_code == 0
        mock_run.assert_called_once()
