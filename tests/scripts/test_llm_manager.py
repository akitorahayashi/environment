"""Tests for the LLM manager script."""
import importlib.util
import signal
import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

MODULE_PATH = Path(__file__).resolve().parents[2] / "ansible" / "scripts" / "shell" / "llm_manager.py"
SPEC = importlib.util.spec_from_file_location("menv_llm_manager", MODULE_PATH)
assert SPEC and SPEC.loader
llm_manager = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = llm_manager
SPEC.loader.exec_module(llm_manager)


@pytest.fixture
def mock_paths(tmp_path, monkeypatch):
    """Mock PID_DIR and service paths."""
    pid_dir = tmp_path / ".tmp"
    pid_dir.mkdir(parents=True, exist_ok=True)
    monkeypatch.setattr(llm_manager, "PID_DIR", pid_dir)
    return pid_dir


class TestLlmManager:
    """Test suite for the LLM manager script."""

    def test_cmd_up(self, mock_paths, capsys):
        """Verify 'up' command starts processes."""
        with patch.object(llm_manager.subprocess, "Popen") as mock_popen:
            mock_process = MagicMock(pid=123)
            mock_popen.return_value = mock_process
            llm_manager.cmd_up("mbk")
            captured = capsys.readouterr()
            assert "Starting mbk LLM runtimes..." in captured.out
            assert mock_popen.call_count == 2  # ollama and mlx
            assert "Started ollama" in captured.out
            assert "Started mlx" in captured.out

    def test_cmd_down(self, mock_paths, capsys):
        """Verify 'down' command stops processes."""
        pid_dir = mock_paths
        (pid_dir / "ollama-mbk.pid").write_text("12345")
        (pid_dir / "mlx-mbk.pid").write_text("54321")

        with patch.object(llm_manager.os, "kill") as mock_kill, patch.object(
            llm_manager, "is_process_running", return_value=True
        ):
            llm_manager.cmd_down("mbk", force=False)
            captured = capsys.readouterr()
            assert "Stopping mbk LLM runtimes..." in captured.out
            mock_kill.assert_any_call(12345, signal.SIGTERM)
            mock_kill.assert_any_call(54321, signal.SIGTERM)
            assert "Stopped ollama (pid 12345)" in captured.out
            assert "Stopped mlx (pid 54321)" in captured.out

    def test_cmd_ps(self, mock_paths, capsys):
        """Verify 'ps' command shows correct status."""
        pid_dir = mock_paths
        (pid_dir / "ollama-mbk.pid").write_text("123")

        with patch.object(
            llm_manager,
            "is_process_running",
            side_effect=lambda pid: pid == 123,
        ):
            llm_manager.cmd_ps("mbk")
            captured = capsys.readouterr()
            assert "ollama: running (pid 123)" in captured.out
            assert "mlx: not running" in captured.out

    def test_main_entrypoint(self):
        """Test the main function with CLI arguments."""
        with patch.object(llm_manager, "cmd_up") as mock_up:
            llm_manager.main(["mbk", "up"])
            mock_up.assert_called_once_with("mbk")

        with patch.object(llm_manager, "cmd_down") as mock_down:
            llm_manager.main(["mmn", "down", "--force"])
            mock_down.assert_called_once_with("mmn", force=True)

    def test_build_parser_lists_targets(self):
        """Ensure parser enforces targets and commands."""
        parser = llm_manager.build_parser()
        # Valid combinations should parse without raising.
        parser.parse_args(["mmn", "up"])
        parser.parse_args(["mbk", "logs"])

        # Invalid target raises SystemExit from argparse.
        with pytest.raises(SystemExit):
            parser.parse_args(["invalid", "up"])

        # Invalid command raises SystemExit from argparse.
        with pytest.raises(SystemExit):
            parser.parse_args(["mbk", "invalid-command"])


class TestIsProcessRunning:
    """Tests for the process detection helper."""

    def test_is_process_running_true(self):
        """Returns True when os.kill succeeds."""
        with patch.object(llm_manager.os, "kill", return_value=None) as mock_kill:
            assert llm_manager.is_process_running(123) is True
            mock_kill.assert_called_once_with(123, 0)

    def test_is_process_running_false(self):
        """Returns False when process does not exist."""
        with patch.object(llm_manager.os, "kill", side_effect=ProcessLookupError):
            assert llm_manager.is_process_running(321) is False

    def test_is_process_running_permission_error(self):
        """Returns True when os.kill raises PermissionError."""
        with patch.object(llm_manager.os, "kill", side_effect=PermissionError):
            assert llm_manager.is_process_running(999) is True
