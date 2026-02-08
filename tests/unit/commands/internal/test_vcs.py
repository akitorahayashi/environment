"""Tests for internal VCS commands."""

from __future__ import annotations

from unittest.mock import patch

import typer.testing

from menv.commands.internal.vcs import vcs_app

runner = typer.testing.CliRunner()

# Single-command Typer app auto-promotes the command,
# so invoke with just arguments (no "delete-submodule" prefix).


class TestDeleteSubmodule:
    """Tests for delete-submodule command."""

    def test_rejects_absolute_path(self) -> None:
        result = runner.invoke(vcs_app, ["/etc/passwd"])
        assert result.exit_code == 1
        assert "Invalid submodule path" in result.output

    def test_rejects_path_traversal(self) -> None:
        result = runner.invoke(vcs_app, ["../escape"])
        assert result.exit_code == 1
        assert "Invalid submodule path" in result.output

    @patch("menv.commands.internal.vcs.subprocess.run")
    def test_calls_git_submodule_steps(self, mock_run) -> None:
        mock_run.return_value.returncode = 0
        result = runner.invoke(vcs_app, ["libs/foo"])
        assert result.exit_code == 0
        assert "deleted successfully" in result.output

        calls = [c.args[0] for c in mock_run.call_args_list]
        assert ["git", "submodule", "deinit", "-f", "libs/foo"] in calls
        assert ["git", "rm", "-f", "-r", "libs/foo"] in calls
        assert ["rm", "-rf", ".git/modules/libs/foo"] in calls

    @patch("menv.commands.internal.vcs.subprocess.run")
    def test_exits_on_subprocess_failure(self, mock_run) -> None:
        from subprocess import CalledProcessError

        mock_run.side_effect = CalledProcessError(1, "git")
        result = runner.invoke(vcs_app, ["libs/foo"])
        assert result.exit_code == 1
