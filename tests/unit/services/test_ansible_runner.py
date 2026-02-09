"""Unit tests for AnsibleRunner service."""

from __future__ import annotations

import subprocess
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest
from rich.console import Console

from menv.protocols.ansible_paths import AnsiblePathsProtocol
from menv.services.ansible_runner import AnsibleRunner


class TestAnsibleRunner:
    @pytest.fixture
    def mock_paths(self) -> MagicMock:
        paths = MagicMock(spec=AnsiblePathsProtocol)
        paths.ansible_dir.return_value = Path("/mock/ansible")
        return paths

    @pytest.fixture
    def mock_console(self) -> MagicMock:
        return MagicMock(spec=Console)

    @pytest.fixture
    def runner(self, mock_paths: MagicMock, mock_console: MagicMock) -> AnsibleRunner:
        return AnsibleRunner(paths=mock_paths, console=mock_console)

    def test_run_playbook_success(
        self, runner: AnsibleRunner, mock_paths: MagicMock, mock_console: MagicMock
    ) -> None:
        with patch("subprocess.Popen") as mock_popen:
            process_mock = MagicMock()
            process_mock.stdout = ["line1\n", "line2\n"]
            process_mock.returncode = 0
            process_mock.wait.return_value = None
            mock_popen.return_value = process_mock

            exit_code = runner.run_playbook(
                profile="test-profile", tags=["tag1", "tag2"], verbose=True
            )

            assert exit_code == 0

            # Verify command construction
            expected_playbook = Path("/mock/ansible/playbook.yml")
            # The code uses Path.home(), so we should probably mock it or just check relative path if possible,
            # but mocking Path.home() is cleaner or just expect what it returns.
            # However, Path.home() returns real home.
            # The implementation: local_config_root = Path.home() / ".config" / "menv" / "roles"
            expected_config_root = Path.home() / ".config" / "menv" / "roles"

            args, kwargs = mock_popen.call_args
            cmd = args[0]

            assert cmd[0] == "ansible-playbook"
            assert cmd[1] == str(expected_playbook)
            assert "-e" in cmd
            assert "profile=test-profile" in cmd
            # Check for config_dir_abs_path
            assert f"config_dir_abs_path={Path('/mock/ansible')}" in cmd
            # Check for repo_root_path
            # Note: The implementation uses ansible_dir.parent as repo_root_path
            assert f"repo_root_path={Path('/mock')}" in cmd
            # Check for local_config_root
            assert f"local_config_root={expected_config_root}" in cmd

            assert "--tags" in cmd
            assert "tag1,tag2" in cmd
            assert "-vvv" in cmd

            # Verify environment
            env = kwargs["env"]
            assert env["ANSIBLE_CONFIG"] == str(Path("/mock/ansible/ansible.cfg"))

            # Verify console output
            mock_console.print.assert_any_call(
                "[bold blue]Running ansible-playbook for profile:[/] test-profile"
            )
            mock_console.print.assert_any_call("[dim]Tags: tag1, tag2[/]")

    def test_run_playbook_file_not_found(
        self, runner: AnsibleRunner, mock_console: MagicMock
    ) -> None:
        with patch("subprocess.Popen", side_effect=FileNotFoundError):
            exit_code = runner.run_playbook(profile="test-profile")

            assert exit_code == 1
            mock_console.print.assert_any_call(
                "[bold red]Error:[/] ansible-playbook not found. "
                "Please ensure Ansible is installed."
            )

    def test_run_playbook_keyboard_interrupt(
        self, runner: AnsibleRunner, mock_console: MagicMock
    ) -> None:
        with patch("subprocess.Popen", side_effect=KeyboardInterrupt):
            exit_code = runner.run_playbook(profile="test-profile")

            assert exit_code == 130
            mock_console.print.assert_any_call("\n[yellow]Interrupted by user[/]")

    def test_run_playbook_failure_exit_code(self, runner: AnsibleRunner) -> None:
        with patch("subprocess.Popen") as mock_popen:
            process_mock = MagicMock()
            process_mock.stdout = []
            process_mock.returncode = 2
            process_mock.wait.return_value = None
            mock_popen.return_value = process_mock

            exit_code = runner.run_playbook(profile="test-profile")

            assert exit_code == 2

    def test_run_playbook_output_streaming(self, runner: AnsibleRunner) -> None:
        with patch("subprocess.Popen") as mock_popen, patch(
            "sys.stdout"
        ) as mock_stdout:
            process_mock = MagicMock()
            process_mock.stdout = ["output line 1\n", "output line 2\n"]
            process_mock.returncode = 0
            mock_popen.return_value = process_mock

            runner.run_playbook(profile="test-profile")

            mock_stdout.write.assert_any_call("output line 1\n")
            mock_stdout.write.assert_any_call("output line 2\n")
            assert mock_stdout.flush.call_count >= 2
