"""Tests for backup command execution."""

from __future__ import annotations

from unittest.mock import MagicMock, patch

from typer.testing import CliRunner

from menv.main import app


class TestBackupExecution:
    """Tests for the backup command execution."""

    @patch("subprocess.Popen")
    @patch("pathlib.Path.exists")
    def test_backup_system_passes_config_dir(
        self, mock_exists, mock_popen, cli_runner: CliRunner
    ) -> None:
        """Test that backup system passes the config directory."""
        # Assume everything exists
        mock_exists.return_value = True

        # Mock Popen process
        mock_process = MagicMock()
        mock_process.stdout = []
        mock_process.wait.return_value = None
        mock_process.returncode = 0
        mock_popen.return_value = mock_process

        result = cli_runner.invoke(app, ["backup", "system"])

        assert result.exit_code == 0

        # Verify Popen call args
        args, _ = mock_popen.call_args
        cmd = args[0]

        # We expect [python, script_path, config_dir, ...]
        assert len(cmd) > 2, f"Command should have arguments: {cmd}"

        # Verify config dir path
        # It should contain 'common'
        assert "common" in str(cmd[2])
