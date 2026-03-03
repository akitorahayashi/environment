"""Tests for internal shell command stubs.

Domain behavior is tested in the Rust menv-internal test suite.
These tests verify the Python stubs report missing binary correctly.
"""

from __future__ import annotations

import typer.testing

from menv.commands.internal.shell import shell_app

runner = typer.testing.CliRunner()


class TestShellStubs:
    """Verify stub commands report missing binary."""

    def test_gen_gemini_aliases_reports_missing_binary(self) -> None:
        result = runner.invoke(shell_app, ["gen-gemini-aliases"])
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_gen_vscode_workspace_reports_missing_binary(self) -> None:
        result = runner.invoke(
            shell_app, ["gen-vscode-workspace", "../path1", "/abs/path2"]
        )
        assert result.exit_code == 1
        assert "menv-internal binary not found" in result.output

    def test_gen_vscode_workspace_requires_paths(self) -> None:
        result = runner.invoke(shell_app, ["gen-vscode-workspace"])
        assert result.exit_code != 0
