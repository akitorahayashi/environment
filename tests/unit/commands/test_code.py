"""Tests for code command."""

from __future__ import annotations

from typer.testing import CliRunner

from menv.main import app


class TestCodeCommand:
    """Tests for the code command."""

    def test_code_help_shows_description(self, cli_runner: CliRunner) -> None:
        """Test that code --help shows description."""
        result = cli_runner.invoke(app, ["code", "--help"])

        assert result.exit_code == 0
        assert "code" in result.output.lower() or "vscode" in result.output.lower()

    def test_code_command_not_found_shows_error(
        self, cli_runner: CliRunner, monkeypatch
    ) -> None:
        """Test that code command shows warning when 'code' CLI is not found."""
        import shutil

        # Mock shutil.which to return None (command not found)
        monkeypatch.setattr(shutil, "which", lambda cmd: None)

        result = cli_runner.invoke(app, ["code"])

        # Should warn and fail
        assert result.exit_code == 1
        assert "Warning" in result.output or "warning" in result.output
        assert "not found" in result.output
        # Check for key parts of the hint text separately to handle line wrapping
        assert "Hint" in result.output or "hint" in result.output
        assert "Command Palette" in result.output
        assert "Install" in result.output

    def test_code_command_success(self, cli_runner: CliRunner, monkeypatch) -> None:
        """Test that code command opens menv project directory successfully."""
        import shutil
        import subprocess
        from unittest.mock import MagicMock

        # Mock shutil.which to return a path (command found)
        monkeypatch.setattr(shutil, "which", lambda cmd: "/usr/local/bin/code")

        # Mock MENV_REPO_PATH to simulate existing repo (skip SSH check)
        class MockPath:
            def exists(self) -> bool:
                return True

            def __truediv__(self, other: str) -> "MockPath":
                return MockPath()

            def __str__(self) -> str:
                return "/Users/test/menv"

        monkeypatch.setattr("menv.commands.code.MENV_REPO_PATH", MockPath())

        # Mock subprocess.run to simulate successful execution
        mock_result = MagicMock()
        mock_result.returncode = 0
        monkeypatch.setattr(subprocess, "run", lambda *args, **kwargs: mock_result)

        result = cli_runner.invoke(app, ["code"])

        assert result.exit_code == 0
        assert "✓" in result.output or "Opened" in result.output
        assert "menv" in result.output

    def test_code_command_finds_project_root(
        self, cli_runner: CliRunner, monkeypatch
    ) -> None:
        """Test that code command correctly finds menv project root."""
        import shutil
        import subprocess
        from pathlib import Path
        from unittest.mock import MagicMock

        # Mock shutil.which to return a path
        monkeypatch.setattr(shutil, "which", lambda cmd: "/usr/local/bin/code")

        # Mock MENV_REPO_PATH to simulate existing repo (skip SSH check)
        class MockPath:
            def exists(self) -> bool:
                return True

            def __truediv__(self, other: str) -> "MockPath":
                return MockPath()

            def __str__(self) -> str:
                return "/Users/test/menv"

        monkeypatch.setattr("menv.commands.code.MENV_REPO_PATH", MockPath())

        # Track what path was passed to subprocess.run
        called_with_path = []

        def mock_run(cmd_list, *args, **kwargs):
            called_with_path.append(cmd_list[1])
            mock_result = MagicMock()
            mock_result.returncode = 0
            return mock_result

        monkeypatch.setattr(subprocess, "run", mock_run)

        result = cli_runner.invoke(app, ["code"])

        # Should have found and opened some path
        assert result.exit_code == 0
        assert len(called_with_path) == 1
        # The path should be a valid directory path (not just ".")
        opened_path = Path(called_with_path[0])
        assert opened_path.name != "."

    def test_code_command_subprocess_error(
        self, cli_runner: CliRunner, monkeypatch
    ) -> None:
        """Test that code command handles subprocess errors gracefully."""
        import shutil
        import subprocess

        # Mock shutil.which to return a path (command found)
        monkeypatch.setattr(shutil, "which", lambda cmd: "/usr/local/bin/code")

        # Mock MENV_REPO_PATH to simulate existing repo (skip SSH check)
        class MockPath:
            def exists(self) -> bool:
                return True

            def __truediv__(self, other: str) -> "MockPath":
                return MockPath()

            def __str__(self) -> str:
                return "/Users/test/menv"

        monkeypatch.setattr("menv.commands.code.MENV_REPO_PATH", MockPath())

        # Mock subprocess.run to raise CalledProcessError
        def mock_run(*args, **kwargs):
            raise subprocess.CalledProcessError(1, "code")

        monkeypatch.setattr(subprocess, "run", mock_run)

        result = cli_runner.invoke(app, ["code"])

        assert result.exit_code == 1
        assert "Error" in result.output or "Failed" in result.output
